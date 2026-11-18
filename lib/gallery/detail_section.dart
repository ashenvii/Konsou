import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../components/app_menu.dart';
import '../components/date_field.dart';
import '../components/star_rating.dart';
import '../components/status_menu_entries.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../detail/provider_page.dart';
import '../detail/title_details.dart';
import '../detail/watch_order.dart';
import '../library/entry_status.dart';
import '../components/cover_image.dart';
import '../components/peek_row.dart';
import '../screens/detail/back_bar.dart';
import '../screens/detail/detail_header.dart';
import '../screens/detail/detail_top.dart';
import '../screens/detail/entry_controls.dart';
import '../screens/detail/next_up_row.dart';
import '../screens/detail/overview_info.dart';
import '../screens/detail/page_picker.dart';
import '../screens/detail/score_strip.dart';
import '../screens/detail/watch_order_strip.dart';

const sampleDetails = TitleDetails(
  malId: 52991,
  name: 'Sousou no Frieren',
  otherName: 'Frieren: Beyond Journey\'s End',
  otherNames: [
    'Frieren at the Funeral',
    'Sousou no Frieren Season 1',
    'Frieren',
    'Journey\'s End',
  ],
  isFull: true,
  fetchedAt: 0,
  mediaType: 'tv',
  airingStatus: 'finished_airing',
  episodes: 28,
  startDate: '2023-09-29',
  endDate: '2024-03-22',
  season: 'fall',
  seasonYear: 2023,
  broadcastDay: 'friday',
  broadcastTime: '23:00',
  secondsPerEpisode: 1560,
  source: 'manga',
  rating: 'pg_13',
  studios: ['Madhouse'],
  genres: ['Adventure', 'Drama', 'Fantasy'],
  score: 9.3,
  rank: 1,
  popularity: 232,
  listUsers: 1100000,
  listCounts: ListCounts(
    watching: 180000,
    completed: 620000,
    onHold: 22000,
    dropped: 9000,
    planned: 270000,
  ),
);

final sampleWatchOrder = WatchOrder([
  const WatchOrderRow(
    malId: 1,
    name: 'Sousou no Frieren',
    isExtra: false,
    isOpenTitle: true,
    mediaType: 'tv',
    startDate: '2023-09-29',
    episodes: 28,
    entryId: 'a',
    status: EntryStatus.watching,
    episodesWatched: 4,
  ),
  const WatchOrderRow(
    malId: 2,
    name: 'Sousou no Frieren: Marumaru no Mahou',
    isExtra: true,
    mediaType: 'ona',
    startDate: '2024-01-12',
    episodes: 12,
    entryId: 'b',
    status: EntryStatus.completed,
  ),
  const WatchOrderRow(
    malId: 3,
    name: 'Sousou no Frieren Season 2',
    isExtra: false,
    isNotAired: true,
    mediaType: 'tv',
    startDate: '2026-01-16',
  ),
  const WatchOrderRow(
    malId: 4,
    name: '',
    isExtra: true,
    isLoadingDetails: true,
    mediaType: 'special',
  ),
]);

const _suggestions = [
  ProviderPage(
    malId: 52991,
    name: 'Sousou no Frieren',
    mediaType: 'tv',
    startDate: '2023-09-29',
    episodes: 28,
  ),
  ProviderPage(
    malId: 59978,
    name: 'Sousou no Frieren 2nd Season',
    mediaType: 'tv',
    startDate: '2026-01-16',
  ),
  ProviderPage(
    malId: 56805,
    name: 'Sousou no Frieren: Marumaru no Mahou',
    mediaType: 'ona',
    startDate: '2024-01-12',
    episodes: 12,
  ),
];

List<MenuEntry> _statusEntries() =>
    statusMenuEntries(current: EntryStatus.watching, onPick: (_) {});

/// The Detail page's parts as the page will draw them: the back bar in both
/// states, the top, the rating and date controls, the entry controls in each
/// state, the watch order strip, the page picker and the overview info.
class DetailSection extends StatefulWidget {
  const DetailSection({super.key});

  @override
  State<DetailSection> createState() => _DetailSectionState();
}

class _DetailSectionState extends State<DetailSection> {
  int? _score = 8;
  DateTime? _started = DateTime(2023, 10, 6);
  int _watched = 4;

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: Tokens.space4, bottom: Tokens.space2),
    child: Text(text, style: AppText.caption(Tokens.inkMuted)),
  );

  @override
  Widget build(BuildContext context) {
    // the page is built for a desktop window; on a narrow screen the gallery
    // scrolls it sideways instead of squeezing it
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth < _stageWidth
              ? _stageWidth
              : constraints.maxWidth,
          child: _page(),
        ),
      ),
    );
  }

  static const _stageWidth = 760.0;

  Widget _controls(int watched, int? total) => EntryControls(
    statusEntries: _statusEntries(),
    status: EntryStatus.watching,
    watched: watched,
    total: total,
    onMinus: () => setState(() => _watched = (_watched - 1).clamp(0, 28)),
    onPlus: () => setState(() => _watched = (_watched + 1).clamp(0, 28)),
    onStep: (n) => setState(() => _watched = n),
  );

  Widget _page() {
    return ProviderScope(
      overrides: [coverStoreProvider.overrideWithValue(null)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Back bar, plain and scrolled'),
          BackBar(
            title: sampleDetails.name,
            scrolled: false,
            onBack: () {},
            onTitle: () {},
          ),
          const SizedBox(height: Tokens.space3),
          BackBar(
            title: sampleDetails.name,
            scrolled: true,
            onBack: () {},
            onTitle: () {},
            status: EntryControls(
              statusEntries: _statusEntries(),
              status: EntryStatus.watching,
              statusOnly: true,
            ),
          ),
          _label('Top: cover, title, controls, scores and facts, next up'),
          DetailTop(
            malId: sampleDetails.malId,
            header: DetailHeader(
              name: sampleDetails.name,
              otherName: sampleDetails.otherName,
            ),
            controls: _controls(_watched, 28),
            facts: ScoreStrip(
              details: sampleDetails,
              mine: ScoreFigure(
                value: _score?.toString(),
                empty: 'Not rated',
                label: 'Your score',
              ),
            ),
            next: NextUpRow(row: sampleWatchOrder.rows[2], onOpen: () {}),
          ),
          _label('Star rating and date field'),
          Row(
            children: [
              StarRating(
                value: _score,
                onChanged: (v) => setState(() => _score = v),
                labelFor: (score) => 'Rate $score',
                clearLabel: 'Clear',
              ),
              const SizedBox(width: Tokens.space5),
              DateField(
                value: _started,
                onChanged: (v) => setState(() => _started = v),
              ),
            ],
          ),
          _label('Entry controls: 1000 episodes, no total, off the list'),
          _controls(4, 1000),
          const SizedBox(height: Tokens.space3),
          _controls(4, null),
          const SizedBox(height: Tokens.space3),
          EntryControls(statusEntries: _statusEntries()),
          _label('Watch order'),
          Text(
            watchOrderSummary(sampleWatchOrder),
            style: AppText.label(Tokens.inkSoft),
          ),
          const SizedBox(height: Tokens.space3),
          PeekRow(
            count: sampleWatchOrder.rows.length,
            minItemWidth: watchOrderCardMinWidth(context),
            arrowTop: (width) =>
                (CoverImage.heightFor(width) - Tokens.controlHeight) / 2,
            itemBuilder: (context, i, width) => WatchOrderCard(
              row: sampleWatchOrder.rows[i],
              width: width,
              isNext: i == 2,
            ),
          ),
          _label('Page picker'),
          PagePicker(
            suggestions: _suggestions,
            onPick: (_) {},
            onNone: () {},
            onSearch: (_) {},
          ),
          _label('Overview info'),
          const OverviewInfo(sampleDetails),
        ],
      ),
    );
  }
}
