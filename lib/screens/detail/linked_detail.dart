import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/detail_providers.dart';
import '../../components/page_frame.dart';
import '../../components/skeleton.dart';
import '../../components/text_action.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/watch_order.dart';
import 'detail_frame.dart';
import 'detail_header.dart';
import 'detail_top.dart';
import 'live_entry_controls.dart';
import 'detail_parts.dart';
import 'score_strip.dart';
import 'watch_order_strip.dart';
import 'your_entry_section.dart';
import 'your_score.dart';

/// The Detail page of a MAL title, on the list or not, as one scroll: the
/// top with the user's record first and a line for anything to note, then
/// every part MAL gives, the watch order and the rest of the user's entry,
/// each reachable from the jump bar.
class LinkedDetail extends ConsumerWidget {
  const LinkedDetail({
    super.key,
    required this.malId,
    required this.onBack,
    required this.onOpenTitle,
    required this.onShowPicker,
    this.entryId,
  });

  final int malId;

  /// The entry the page was opened from, when two share this title.
  final String? entryId;
  final VoidCallback onBack;
  final void Function(int malId, {String? entryId}) onOpenTitle;

  /// "Wrong title" unlinked this entry: go to its page picker.
  final ValueChanged<String> onShowPicker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = detailPageProvider(malId, entryId: entryId);
    final page = ref.watch(provider);
    final data = page.value;
    if (data == null) {
      return DetailFrame(
        title: '',
        onBack: onBack,
        top: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailTop(
              malId: malId,
              loading: !page.hasError,
              header: page.hasError
                  ? const SizedBox.shrink()
                  : const SkeletonLines(title: 0.5, line: 0.3),
            ),
            if (page.hasError) const _Notice('This title could not be read.'),
          ],
        ),
      );
    }

    final details = data.details;
    final entry = data.entry;
    final fetching = data.fetch == DetailFetch.running;
    final order = ref.watch(watchOrderProvider(malId)).value;
    final name = switch (details?.name) {
      final name? when name.isNotEmpty => name,
      _ => entry?.name ?? '',
    };
    final hasControls = entry != null || details != null;
    void openRow(WatchOrderRow row) =>
        onOpenTitle(row.malId, entryId: row.entryId);
    final note = _savedNote(data.fetch);

    return DetailFrame(
      title: name,
      onBack: onBack,
      malId: malId,
      hideCover: data.isHidden,
      status: hasControls
          ? LiveEntryControls(entry: entry, details: details, statusOnly: true)
          : null,
      top: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailTop(
            malId: malId,
            hidden: data.isHidden,
            loading: details == null && fetching,
            header: name.isEmpty
                ? (fetching
                      ? const SkeletonLines(title: 0.5, line: 0.3)
                      : const SizedBox.shrink())
                : DetailHeader(name: name, otherName: details?.otherName),
            controls: hasControls
                ? LiveEntryControls(entry: entry, details: details)
                : null,
            facts: details == null
                ? null
                : ScoreStrip(
                    details: details,
                    mine: entry == null ? null : YourScore(entry: entry),
                  ),
          ),
          // the one place under the top for a line to note; the earlier
          // seasons banner goes here too
          if (details != null && note != null)
            _Notice(
              note,
              onRetry: data.fetch == DetailFetch.gone
                  ? null
                  : () => _retry(ref),
            ),
          if (details == null)
            Padding(
              padding: PageFrame.content,
              child: _missing(data.fetch, ref),
            ),
        ],
      ),
      parts: [
        if (details != null)
          DetailPart(
            'Overview',
            OverviewPart(
              details: details,
              hidden: data.isHidden,
              fetching: fetching,
            ),
          ),
        if (order != null && order.rows.isNotEmpty)
          DetailPart(
            'Watch order',
            WatchOrderSection(order: order, onOpen: openRow),
          ),
        if (details != null && StatsPart.hasAny(details))
          DetailPart('Stats', StatsPart(details: details)),
        if (details != null && MusicPart.hasAny(details))
          DetailPart('Music', MusicPart(details: details)),
        if (details != null && details.videos.isNotEmpty)
          DetailPart('Trailers', TrailersPart(videos: details.videos)),
        if (details != null && details.pictures.isNotEmpty && !data.isHidden)
          DetailPart(
            'Pictures',
            PicturesPart(malId: malId, pictures: details.pictures),
          ),
        if (details != null && details.recommendations.isNotEmpty)
          DetailPart(
            'Recommendations',
            RecommendationsPart(
              titles: details.recommendations,
              onOpen: (id) => onOpenTitle(id),
            ),
          ),
        if (details != null && details.manga.isNotEmpty)
          DetailPart('Manga', MangaPart(titles: details.manga)),
        if (entry != null)
          DetailPart(
            'Your entry',
            YourEntrySection(
              key: ValueKey(entry.entryId),
              entry: entry,
              onUnlinked: () => onShowPicker(entry.entryId),
            ),
          ),
      ],
      footer: details == null
          ? null
          : Text(
              'Data from MyAnimeList',
              style: AppText.caption(Tokens.inkMuted),
            ),
    );
  }

  void _retry(WidgetRef ref) =>
      ref.read(detailPageProvider(malId, entryId: entryId).notifier).retry();

  // the line over saved details that could not be refreshed
  static String? _savedNote(DetailFetch fetch) => switch (fetch) {
    DetailFetch.offline ||
    DetailFetch.failed => 'Offline, showing saved details',
    DetailFetch.gone =>
      'MyAnimeList no longer has this page, showing saved details',
    DetailFetch.idle || DetailFetch.running => null,
  };

  // nothing saved for the title
  Widget _missing(DetailFetch fetch, WidgetRef ref) => switch (fetch) {
    DetailFetch.running => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLines(title: 0.6, line: 0.4),
        SizedBox(height: Tokens.space4),
        SkeletonLines(title: 0.5, line: 0.3),
      ],
    ),
    DetailFetch.gone => const _Notice(
      'MyAnimeList no longer has this page.',
      inset: false,
    ),
    DetailFetch.idle || DetailFetch.offline || DetailFetch.failed => _Notice(
      "Can't reach MyAnimeList.",
      onRetry: () => _retry(ref),
      inset: false,
    ),
  };
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, {this.onRetry, this.inset = true});

  final String text;
  final VoidCallback? onRetry;

  /// Off when the parent already keeps the page's side space.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: inset
          ? PageFrame.content.copyWith(top: Tokens.space4, bottom: 0)
          : const EdgeInsets.only(bottom: Tokens.space5),
      child: Row(
        children: [
          Flexible(child: Text(text, style: AppText.label(Tokens.inkSoft))),
          if (onRetry != null) ...[
            const SizedBox(width: Tokens.space2),
            TextAction(label: 'Retry', onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}
