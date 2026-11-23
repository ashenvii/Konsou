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
    this.entryId,
    this.malId,
    this.status,
    this.episodes,
    this.airing,
  });

  final String name;

  /// The small line under the name.
  final String line;

  /// Set for a title on the list.
  final String? entryId;
  final int? malId;

  /// Set for a title on the list.
  final EntryStatus? status;
  final int? episodes;

  /// MAL's airing status of a title found online.
  final String? airing;

  bool get onList => entryId != null;
  bool get completed => status == EntryStatus.completed;
}

QuickRow quickRowFromEntry(LibraryEntry entry) {
  return QuickRow(
    name: formatTitle(entry.name),
    line: [
      formatTypeYear(entry.mediaType, entry.startDate),
      formatProgress(entry.episodesWatched, entry.episodes),
    ].where((part) => part.isNotEmpty).join(' · '),
    entryId: entry.entryId,
    malId: entry.malId,
    status: entry.status,
    episodes: entry.episodes,
  );
}

/// A title MAL found, as a row for a title not on the list.
QuickRow quickRowFromPage(Map<String, dynamic> page, TitleLanguage language) {
  final alternatives = page['alternative_titles'] as Map?;
  final name =
      orderTitles(
        language,
        romaji: page['title'] as String?,
        english: alternatives?['en'] as String?,
        japanese: alternatives?['ja'] as String?,
      ).firstOrNull ??
      '';
  final episodes = page['num_episodes'] as int?;
  return QuickRow(
    name: name,
    line: formatTypeYear(
      page['media_type'] as String?,
      page['start_date'] as String?,
    ),
    malId: page['id'] as int,
    episodes: episodes != null && episodes > 0 ? episodes : null,
    airing: page['status'] as String?,
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
