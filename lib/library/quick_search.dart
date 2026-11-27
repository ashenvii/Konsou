import 'aired_episodes.dart';
import 'entry_status.dart';
import 'library_row.dart';
import 'row_labels.dart';
import 'title_language.dart';

/// Rows shown at first in each group, and how many more one Load more adds.
const quickFirst = quickPage;
const quickPage = 10;

/// One result in Quick search: an entry on the list, or a title found online.
class QuickRow {
  const QuickRow({
    required this.name,
    required this.line,
    required this.count,
    this.entryId,
    this.malId,
    this.status,
    this.episodes,
    this.malScore,
    this.airing,
    this.isLoadingDetails = false,
    this.isScorePending = false,
  });

  final String name;

  /// The small line under the name.
  final String line;

  /// The episode column's count.
  final CardCount count;

  /// Set for a title on the list.
  final String? entryId;
  final int? malId;

  /// Set for a title on the list.
  final EntryStatus? status;
  final int? episodes;
  final double? malScore;

  /// MAL's airing status of a title found online.
  final String? airing;

  /// On the list with a MAL page whose details have not come in yet.
  final bool isLoadingDetails;

  /// Details saved, but MAL's score not asked for yet.
  final bool isScorePending;

  bool get onList => entryId != null;
  bool get completed => status == EntryStatus.completed;

  /// On the list with no MAL page found yet.
  bool get isNotLinked => onList && malId == null;
}

QuickRow quickRowFromEntry(LibraryEntry entry) {
  return QuickRow(
    name: formatTitle(entry.name),
    line: entry.malId == null
        ? 'Not linked'
        : formatTypeWhen(
            entry.mediaType,
            entry.startDate,
            notAired: entry.isNotAired,
          ),
    count: countCard(
      onList: true,
      watched: entry.episodesWatched,
      total: entry.episodes,
    ),
    entryId: entry.entryId,
    malId: entry.malId,
    status: entry.status,
    episodes: entry.episodes,
    malScore: entry.malScore,
    isLoadingDetails: entry.malId != null && !entry.hasDetails,
    isScorePending: entry.scorePending,
  );
}

/// A title MAL found, as a row for a title not on the list. [now] counts the
/// episodes out so far of a series still airing.
QuickRow quickRowFromPage(
  Map<String, dynamic> page,
  TitleLanguage language, {
  required DateTime now,
}) {
  final alternatives = page['alternative_titles'] as Map?;
  final name =
      orderTitles(
        language,
        romaji: page['title'] as String?,
        english: alternatives?['en'] as String?,
        japanese: alternatives?['ja'] as String?,
      ).firstOrNull ??
      '';
  final given = page['num_episodes'] as int?;
  final episodes = given != null && given > 0 ? given : null;
  final mediaType = page['media_type'] as String?;
  final startDate = page['start_date'] as String?;
  final airing = page['status'] as String?;
  return QuickRow(
    name: name,
    line: formatTypeWhen(
      mediaType,
      startDate,
      notAired: airing == 'not_yet_aired',
    ),
    count: countCard(
      onList: false,
      total: episodes,
      // search answers carry no broadcast time, so the day's start stands in
      aired: countAiredInListing(page, now),
    ),
    malId: page['id'] as int,
    episodes: episodes,
    malScore: (page['mean'] as num?)?.toDouble(),
    airing: airing,
  );
}

class QuickState {
  const QuickState({
    this.open = false,
    this.query = '',
    this.recent = const [],
    this.mine = const [],
    this.online = const [],
    this.mineShown = quickFirst,
    this.onlineShown = quickFirst,
    this.searching = false,
    this.paging = false,
    this.onlineMore = false,
    this.failed = false,
    this.focus = 0,
  });

  final bool open;

  /// What is being searched for, trimmed. Empty shows the recent entries.
  final String query;
  final List<QuickRow> recent;

  /// Every match on the list, and every title found online so far.
  final List<QuickRow> mine;
  final List<QuickRow> online;
  final int mineShown;
  final int onlineShown;

  /// An online search is running, so skeleton rows hold the space.
  final bool searching;

  /// The running search is for the next page, so the rows already shown stay
  /// and skeleton rows follow them. A new word keeps the old rows until its
  /// own arrive, with no skeletons, so the list never blinks empty.
  final bool paging;

  /// More online results can be asked for.
  final bool onlineMore;
  final bool failed;

  /// The highlighted row; one past the last row is the Load more row.
  final int focus;

  bool get typing => query.isNotEmpty;

  List<QuickRow> get shownMine => mine.take(mineShown).toList();
  List<QuickRow> get shownOnline => online.take(onlineShown).toList();

  /// The rows in order, for moving through them.
  List<QuickRow> get rows => typing ? [...shownMine, ...shownOnline] : recent;

  /// Nothing more is offered while a search is still coming in.
  bool get hasMore =>
      typing &&
      !searching &&
      (mine.length > mineShown || online.length > onlineShown || onlineMore);

  /// The rows plus Load more, if it shows.
  int get itemCount => rows.length + (hasMore ? 1 : 0);

  QuickState copyWith({
    bool? open,
    String? query,
    List<QuickRow>? recent,
    List<QuickRow>? mine,
    List<QuickRow>? online,
    int? mineShown,
    int? onlineShown,
    bool? searching,
    bool? paging,
    bool? onlineMore,
    bool? failed,
    int? focus,
  }) => QuickState(
    open: open ?? this.open,
    query: query ?? this.query,
    recent: recent ?? this.recent,
    mine: mine ?? this.mine,
    online: online ?? this.online,
    mineShown: mineShown ?? this.mineShown,
    onlineShown: onlineShown ?? this.onlineShown,
    searching: searching ?? this.searching,
    paging: paging ?? this.paging,
    onlineMore: onlineMore ?? this.onlineMore,
    failed: failed ?? this.failed,
    focus: focus ?? this.focus,
  );
}
