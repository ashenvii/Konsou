import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/detail_providers.dart';
import '../../app/providers.dart';
import '../../components/page_frame.dart';
import '../../components/skeleton.dart';
import '../../components/text_action.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/watch_order.dart';
import 'detail_frame.dart';
import 'detail_header.dart';
import 'detail_hero.dart';
import 'detail_tab_bar.dart';
import 'live_entry_bar.dart';
import 'my_entry_tab.dart';
import 'overview_tab.dart';
import 'score_strip.dart';
import 'watch_order_tab.dart';

enum DetailTab {
  overview('Overview'),
  watchOrder('Watch order'),
  myEntry('My entry');

  const DetailTab(this.label);

  final String label;
}

/// The Detail page of a MAL title, on the list or not.
class LinkedDetail extends ConsumerStatefulWidget {
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
  ConsumerState<LinkedDetail> createState() => _LinkedDetailState();
}

class _LinkedDetailState extends ConsumerState<LinkedDetail> {
  var _tab = DetailTab.overview;

  @override
  Widget build(BuildContext context) {
    final provider = detailPageProvider(widget.malId, entryId: widget.entryId);
    // MAL's extra pictures come with the full details: look for the hero again
    ref.listen(provider, (before, now) {
      final wasFull = before?.value?.details?.isFull ?? false;
      final isFull = now.value?.details?.isFull ?? false;
      if (!wasFull && isFull) ref.invalidate(heroFileProvider(widget.malId));
    });
    final page = ref.watch(provider);
    final data = page.value;
    if (data == null) {
      return DetailFrame(
        title: '',
        onBack: widget.onBack,
        children: [
          DetailHero(
            malId: widget.malId,
            loading: !page.hasError,
            header: page.hasError
                ? const SizedBox.shrink()
                : const SkeletonLines(title: 0.5, line: 0.3),
          ),
          if (page.hasError) const _Notice('This title could not be read.'),
        ],
      );
    }

    final details = data.details;
    final entry = data.entry;
    final fetching = data.fetch == DetailFetch.running;
    final order = ref.watch(watchOrderProvider(widget.malId)).value;
    final tabs = [
      DetailTab.overview,
      if (order != null && order.rows.isNotEmpty) DetailTab.watchOrder,
      if (entry != null) DetailTab.myEntry,
    ];
    // a tab that went away, such as My entry after Remove, falls back
    final tab = tabs.contains(_tab) ? _tab : DetailTab.overview;
    final name = switch (details?.name) {
      final name? when name.isNotEmpty => name,
      _ => entry?.name ?? '',
    };

    return DetailFrame(
      title: name,
      onBack: widget.onBack,
      bar: entry == null && details == null
          ? null
          : LiveEntryBar(entry: entry, details: details),
      children: [
        DetailHero(
          malId: widget.malId,
          hidden: data.isHidden,
          loading: details == null && fetching,
          header: name.isEmpty
              ? (fetching
                    ? const SkeletonLines(title: 0.5, line: 0.3)
                    : const SizedBox.shrink())
              : DetailHeader(
                  name: name,
                  otherName: details?.otherName,
                  synonyms: details?.otherNames ?? const [],
                ),
          facts: details != null && ScoreStrip.hasAnything(details)
              ? ScoreStrip(details: details)
              : null,
        ),
        if (tabs.length > 1)
          DetailTabBar(
            labels: [for (final choice in tabs) choice.label],
            selected: tabs.indexOf(tab),
            onSelect: (i) => setState(() => _tab = tabs[i]),
          ),
        if (details != null && _savedNote(data.fetch) != null)
          _Notice(
            _savedNote(data.fetch)!,
            onRetry: data.fetch == DetailFetch.gone ? null : _retry,
          ),
        Padding(
          padding: PageFrame.content.copyWith(top: Tokens.space5),
          child: switch (tab) {
            DetailTab.overview =>
              details == null
                  ? _missing(data.fetch)
                  : OverviewTab(
                      details: details,
                      hidden: data.isHidden,
                      fetching: fetching,
                    ),
            DetailTab.watchOrder => WatchOrderTab(
              order: order!,
              onOpen: _openRow,
            ),
            DetailTab.myEntry => MyEntryTab(
              key: ValueKey(entry!.entryId),
              entry: entry,
              onUnlinked: () => widget.onShowPicker(entry.entryId),
            ),
          },
        ),
      ],
    );
  }

  void _retry() => ref
      .read(detailPageProvider(widget.malId, entryId: widget.entryId).notifier)
      .retry();

  void _openRow(WatchOrderRow row) =>
      widget.onOpenTitle(row.malId, entryId: row.entryId);

  // the line over saved details that could not be refreshed
  static String? _savedNote(DetailFetch fetch) => switch (fetch) {
    DetailFetch.offline ||
    DetailFetch.failed => 'Offline, showing saved details',
    DetailFetch.gone =>
      'MyAnimeList no longer has this page, showing saved details',
    DetailFetch.idle || DetailFetch.running => null,
  };

  // nothing saved for the title
  Widget _missing(DetailFetch fetch) => switch (fetch) {
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
      onRetry: _retry,
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
          : EdgeInsets.zero,
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
