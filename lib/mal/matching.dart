import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/databases.dart';
import '../data/details_database.dart';
import '../data/edit_clock.dart';
import '../data/record_database.dart';
import '../search/title_tree.dart';
import '../search/title_words.dart';
import 'detail_request.dart';
import 'request_gate.dart';
import 'search_request.dart';
import 'trickle.dart';

enum MatchOutcome { linked, suggested, nothing, failed }

const maxSuggestions = 5;

/// How long until an entry Konsou could not link is searched again; the same
/// wait as a gone page, since titles get provider pages after they are added.
const matchRetry = goneRecheck;

final _brackets = RegExp(r'\s*[(\[][^)\]]*[)\]]');
final _firstBreak = RegExp(r':| - ');

/// What Konsou searches for a name, in order. MAL finds nothing when any word
/// is missing from a title, so each query drops what is most likely extra.
List<String> buildMatchQueries(String name) {
  final full = name.trim();
  final withoutBrackets = full.replaceAll(_brackets, '').trim();
  final beforeBreak = withoutBrackets.split(_firstBreak).first.trim();
  final queries = <String>[];
  for (final query in [full, withoutBrackets, beforeBreak]) {
    if (query.runes.length >= minQueryLength && !queries.contains(query)) {
      queries.add(query);
    }
  }
  return queries;
}

/// The words of a name that decide a suggestion: each once, leaving out words
/// of 3 letters or fewer ("the", "of", "out") unless nothing longer is left.
List<String> pickNameWords(String name) {
  final words = foldWords(name).toSet().toList();
  final long = [
    for (final word in words)
      if (word.runes.length > 3) word,
  ];
  return long.isEmpty ? words : long;
}

/// How many of [nameWords] appear in the page's best title. Exact words only:
/// a saved name is a real title, so a typo allowance here mostly pairs words
/// like "iris" and "irish".
int countSharedWords(List<String> nameWords, Map<String, dynamic> page) {
  var best = 0;
  for (final title in readProviderTitles(page)) {
    final titleWords = foldWords(title).toSet();
    final shared = nameWords.where(titleWords.contains).length;
    if (shared > best) best = shared;
  }
  return best;
}

/// A search the user typed, and the query whose results are shown when the
/// typed one found nothing and a corrected one did.
class PageSearch {
  PageSearch(
    this.results, {
    required this.typedQuery,
    required this.shownQuery,
  });

  final List<Map<String, dynamic>> results;
  final String typedQuery;
  final String shownQuery;

  bool get isCorrected => shownQuery != typedQuery;
}

/// Finds provider pages for not-linked entries: links one when it is sure,
/// otherwise keeps suggestions for the user to pick from.
class Matching {
  Matching({
    required this.databases,
    required this.searchRequest,
    required this.detailRequest,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Databases databases;
  final SearchRequest searchRequest;
  final DetailRequest detailRequest;
  final DateTime Function() _now;
  var _stopped = false;

  RecordDatabase get _record => databases.record;
  DetailsDatabase get _details => databases.details;

  /// Matches every not-linked entry that is due, until done or [stop].
  Future<void> run() async {
    _stopped = false;
    final failed = <String>{};
    while (!_stopped) {
      final entryId = await _nextEntry(failed);
      if (entryId == null) return;
      if (await matchEntry(entryId) == MatchOutcome.failed) failed.add(entryId);
    }
  }

  void stop() => _stopped = true;

  Future<MatchOutcome> matchEntry(
    String entryId, {
    Lane lane = Lane.trickle,
  }) async {
    final entry = await _readEntry(entryId);
    final declined = await _readDeclined(entryId);
    final nameWords = pickNameWords(entry.name);
    var offered = <_Offer>[];
    for (final query in buildMatchQueries(entry.name)) {
      final results = await searchRequest.search(query, lane: lane);
      if (results == null) return MatchOutcome.failed;
      offered = [
        for (final (index, page) in results.indexed)
          if (!declined.contains(page['id']) && page['id'] != entry.malId)
            if (countSharedWords(nameWords, page) case final shared
                when shared * 2 >= nameWords.length)
              _Offer(
                page,
                isExact: readProviderTitles(page)
                    .any((title) => isSameTitle(title, entry.name)),
                sharedWords: shared,
                index: index,
              ),
      ];
      if (offered.isNotEmpty) break;
    }

    final exact = [
      for (final offer in offered)
        if (offer.isExact) offer.page,
    ];
    if (exact.length == 1 && await _canLink(entryId, entry, exact.single)) {
      await linkEntry(entryId, exact.single['id'] as int, lane: lane);
      return MatchOutcome.linked;
    }
    offered.sort((a, b) {
      if (a.isExact != b.isExact) return a.isExact ? -1 : 1;
      if (a.sharedWords != b.sharedWords) return b.sharedWords - a.sharedWords;
      return a.index - b.index;
    });
    await _saveSuggestions(entryId, [
      for (final offer in offered.take(maxSuggestions)) offer.page,
    ]);
    return offered.isEmpty ? MatchOutcome.nothing : MatchOutcome.suggested;
  }

  /// Points the entry at a provider page, replacing any old one, and fetches
  /// its details.
  Future<void> linkEntry(
    String entryId,
    int malId, {
    required Lane lane,
    bool full = false,
  }) async {
    await _record.transaction(() async {
      await _record
          .into(_record.entryReference)
          .insertOnConflictUpdate(
            EntryReferenceCompanion.insert(
              entryId: entryId,
              provider: 'mal',
              providerId: malId,
            ),
          );
      await _markLinkChanged(entryId);
    });
    await _clearSearch(entryId);
    await detailRequest.fetch(malId, lane: lane, full: full);
  }

  /// The user's "None of these": every page shown is declined.
  Future<void> declineSuggestions(String entryId) async {
    final shown = await (_details.select(
      _details.matchSuggestion,
    )..where((row) => row.entryId.equals(entryId))).get();
    for (final row in shown) {
      await _decline(entryId, row.providerId);
    }
    await _deleteSuggestions(entryId);
  }

  /// The user's "Wrong title": the entry is not linked again and that page is
  /// declined, so the next search looks past it. An entry with no name of its
  /// own keeps the page's title, so it can still be read and searched for.
  Future<void> unlinkEntry(String entryId) async {
    final entry = await _readEntry(entryId);
    final malId = entry.malId;
    if (malId == null) return;
    await _record.transaction(() async {
      await (_record.delete(_record.entryReference)..where(
            (ref) => ref.entryId.equals(entryId) & ref.provider.equals('mal'),
          ))
          .go();
      await _record.customUpdate(
        "UPDATE entry SET name = ? WHERE entry_id = ? AND ifnull(name, '') = ''",
        variables: [
          Variable.withString(entry.name),
          Variable.withString(entryId),
        ],
        updates: {_record.entry},
      );
      await _markLinkChanged(entryId);
      await _decline(entryId, malId);
    });
    await _clearSearch(entryId);
    await (_details.delete(
      _details.franchiseLink,
    )..where((row) => row.entryId.equals(entryId))).go();
  }

  /// "Wrong title" from the Detail page: unlinks, then looks for the right
  /// page at once.
  Future<MatchOutcome> replaceWrongTitle(String entryId) async {
    await unlinkEntry(entryId);
    return matchEntry(entryId, lane: Lane.screen);
  }

  /// Searches the provider for what the user typed. When that finds nothing,
  /// each word is corrected from [tree] and the search runs once more.
  Future<PageSearch?> searchPages(String typed, TitleTree<Object> tree) async {
    final results = await searchRequest.search(typed, lane: Lane.screen);
    if (results == null) return null;
    final corrected = tree.correctQuery(typed);
    if (results.isNotEmpty ||
        corrected.isEmpty ||
        corrected == foldWords(typed).join(' ')) {
      return PageSearch(results, typedQuery: typed, shownQuery: typed);
    }
    final retried = await searchRequest.search(corrected, lane: Lane.screen);
    if (retried == null) return null;
    return PageSearch(retried, typedQuery: typed, shownQuery: corrected);
  }

  Future<bool> _canLink(
    String entryId,
    _MatchEntry entry,
    Map<String, dynamic> page,
  ) async {
    final episodes = page['num_episodes'] as int? ?? 0;
    if (episodes > 0 && entry.watched > episodes) return false;
    final usedElsewhere =
        await (_record.select(_record.entryReference)..where(
              (ref) =>
                  ref.provider.equals('mal') &
                  ref.providerId.equals(page['id'] as int) &
                  ref.entryId.equals(entryId).not(),
            ))
            .get();
    return usedElsewhere.isEmpty;
  }

  Future<void> _markLinkChanged(String entryId) async {
    final changedAt = await readEditTime(_record, _now());
    await (_record.update(_record.entry)
          ..where((entry) => entry.entryId.equals(entryId)))
        .write(EntryCompanion(linkChangedAt: Value(changedAt)));
  }

  Future<void> _decline(String entryId, int malId) => _record
      .into(_record.matchDecline)
      .insert(
        MatchDeclineCompanion.insert(
          entryId: entryId,
          provider: 'mal',
          providerId: malId,
          declinedAt: _now().millisecondsSinceEpoch,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> _saveSuggestions(
    String entryId,
    List<Map<String, dynamic>> pages,
  ) {
    final foundAt = _now().millisecondsSinceEpoch;
    return _details.transaction(() async {
      await _deleteSuggestions(entryId);
      for (var i = 0; i < pages.length; i++) {
        await _details
            .into(_details.matchSuggestion)
            .insert(
              MatchSuggestionCompanion.insert(
                entryId: entryId,
                provider: 'mal',
                providerId: pages[i]['id'] as int,
                position: i,
                json: jsonEncode(pages[i]),
                foundAt: foundAt,
              ),
            );
      }
      await _details
          .into(_details.matchAttempt)
          .insertOnConflictUpdate(
            MatchAttemptCompanion.insert(entryId: entryId, searchedAt: foundAt),
          );
    });
  }

  Future<void> _deleteSuggestions(String entryId) => (_details.delete(
    _details.matchSuggestion,
  )..where((row) => row.entryId.equals(entryId))).go();

  Future<void> _clearSearch(String entryId) => _details.transaction(() async {
    await _deleteSuggestions(entryId);
    await (_details.delete(
      _details.matchAttempt,
    )..where((row) => row.entryId.equals(entryId))).go();
  });

  /// The name to search: a gone page's last title, else the entry's own name.
  Future<_MatchEntry> _readEntry(String entryId) async {
    final row = await _record
        .customSelect(
          '''
      SELECT entry.name, entry.episodes_watched, reference.provider_id,
        detail.title
      FROM entry
      LEFT JOIN entry_reference reference
        ON reference.entry_id = entry.entry_id AND reference.provider = 'mal'
      LEFT JOIN details.detail ON detail.provider = 'mal'
        AND detail.provider_id = reference.provider_id
      WHERE entry.entry_id = ?
      ''',
          variables: [Variable.withString(entryId)],
        )
        .getSingle();
    return _MatchEntry(
      name: row.read<String?>('title') ?? row.read<String?>('name') ?? '',
      watched: row.read<int>('episodes_watched'),
      malId: row.read<int?>('provider_id'),
    );
  }

  Future<Set<int>> _readDeclined(String entryId) async {
    final rows =
        await (_record.select(_record.matchDecline)..where(
              (row) => row.entryId.equals(entryId) & row.provider.equals('mal'),
            ))
            .get();
    return {for (final row in rows) row.providerId};
  }

  /// The next entry with no working provider page that has not been searched
  /// for lately, in the trickle's order.
  Future<String?> _nextEntry(Set<String> skip) async {
    final retryBefore = _now().subtract(matchRetry).millisecondsSinceEpoch;
    final rows = await _record
        .customSelect(
          '''
      SELECT entry.entry_id
      FROM entry
      LEFT JOIN entry_reference reference
        ON reference.entry_id = entry.entry_id AND reference.provider = 'mal'
      LEFT JOIN details.gone_page ON gone_page.provider = 'mal'
        AND gone_page.provider_id = reference.provider_id
      LEFT JOIN details.match_attempt
        ON match_attempt.entry_id = entry.entry_id
      WHERE (reference.provider_id IS NULL OR gone_page.provider_id IS NOT NULL)
        AND (match_attempt.searched_at IS NULL
          OR match_attempt.searched_at <= ?)
        AND entry.entry_id NOT IN (${List.filled(skip.length, '?').join(', ')})
      ORDER BY $trickleOrder
      LIMIT 1
      ''',
          variables: [
            Variable.withInt(retryBefore),
            for (final entryId in skip) Variable.withString(entryId),
          ],
        )
        .get();
    return rows.isEmpty ? null : rows.single.read<String>('entry_id');
  }
}

class _MatchEntry {
  _MatchEntry({required this.name, required this.watched, this.malId});

  final String name;
  final int watched;
  final int? malId;
}

/// A search result that may be offered, and what decides its place: titles
/// equal to the name first, then most shared words, then MAL's order.
class _Offer {
  _Offer(
    this.page, {
    required this.isExact,
    required this.sharedWords,
    required this.index,
  });

  final Map<String, dynamic> page;
  final bool isExact;
  final int sharedWords;
  final int index;
}
