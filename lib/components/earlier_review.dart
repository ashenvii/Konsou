import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'floating_panel.dart';
import 'smooth_scroll.dart';
import '../library/earlier_titles.dart';
import 'app_button.dart';
import 'app_checkbox.dart';
import 'text_action.dart';

class EarlierReviewWords {
  const EarlierReviewWords({
    required this.heading,
    required this.extrasHeading,
    required this.notNow,
    required this.mark,
    required this.storiesHeading,
    required this.all,
    required this.none,
    required this.selected,
    required this.mediaType,
    required this.episodes,
    required this.status,
  });

  final String heading;
  final String extrasHeading;
  final String notNow;
  final String Function(int count) mark;

  final String storiesHeading;
  final String all;
  final String none;
  final String Function(int count, int total) selected;
  final String Function(String type) mediaType;
  final String Function(int count) episodes;
  final String Function(String? stored) status;
}

const _bulkFrom = 4;

class EarlierReview extends StatefulWidget {
  const EarlierReview({
    super.key,
    required this.titles,
    required this.words,
    required this.onMark,
    required this.onNotNow,
    this.cover,
  });

  final Widget Function(EarlierTitle title, double width)? cover;

  final List<EarlierTitle> titles;
  final EarlierReviewWords words;
  final ValueChanged<List<EarlierTitle>> onMark;
  final VoidCallback onNotNow;

  @override
  State<EarlierReview> createState() => _EarlierReviewState();
}

class _EarlierReviewState extends State<EarlierReview> {
  final _scroll = SmoothScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  late final Set<int> _ticked = {
    for (final title in widget.titles)
      if (!title.isExtra) title.malId,
  };

  void _tick(Iterable<EarlierTitle> titles, bool on) => setState(() {
    for (final title in titles) {
      on ? _ticked.add(title.malId) : _ticked.remove(title.malId);
    }
  });

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    final titles = widget.titles;
    final stories = [
      for (final title in titles)
        if (!title.isExtra) title,
    ];
    final extras = [
      for (final title in titles)
        if (title.isExtra) title,
    ];
    final chosen = [
      for (final title in titles)
        if (_ticked.contains(title.malId)) title,
    ];
    Widget group(String heading, List<EarlierTitle> members) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHeading(heading: heading, count: members.length),
        for (final title in members)
          _TitleRow(
            title: title,
            words: words,
            cover: widget.cover,
            ticked: _ticked.contains(title.malId),
            onChanged: (on) => _tick([title], on),
          ),
      ],
    );
    return FloatingPanel(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(words.heading, style: AppText.label(Tokens.ink, bold: true)),
            const SizedBox(height: Tokens.space1),
            Text(
              words.selected(chosen.length, titles.length),
              style: AppText.caption(Tokens.inkSoft),
            ),
            const SizedBox(height: Tokens.space2),
            Flexible(
              child: SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (stories.isNotEmpty)
                      group(words.storiesHeading, stories),
                    if (extras.isNotEmpty) group(words.extrasHeading, extras),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Tokens.space4),
            Row(
              children: [
                if (titles.length >= _bulkFrom) ...[
                  TextAction(
                    label: words.all,
                    quiet: true,
                    onPressed: chosen.length == titles.length
                        ? null
                        : () => _tick(titles, true),
                  ),
                  TextAction(
                    label: words.none,
                    quiet: true,
                    onPressed: chosen.isEmpty
                        ? null
                        : () => _tick(titles, false),
                  ),
                ],
                const Spacer(),
                TextAction(
                  label: words.notNow,
                  onPressed: widget.onNotNow,
                  quiet: true,
                ),
                const SizedBox(width: Tokens.space2),
                AppButton(
                  label: words.mark(chosen.length),
                  onPressed: chosen.isEmpty
                      ? null
                      : () => widget.onMark(chosen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.heading, required this.count});

  final String heading;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Tokens.space2, bottom: Tokens.space1),
      child: Row(
        children: [
          Text(heading, style: AppText.caption(Tokens.inkSoft)),
          const SizedBox(width: Tokens.space2),
          Text('$count', style: AppText.caption(Tokens.inkMuted)),
          const SizedBox(width: Tokens.space3),
          Expanded(child: Container(height: 1, color: Tokens.line)),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.words,
    required this.cover,
    required this.ticked,
    required this.onChanged,
  });

  final EarlierTitle title;
  final EarlierReviewWords words;
  final Widget Function(EarlierTitle title, double width)? cover;
  final bool ticked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final start = title.startDate;
    final episodes = title.episodes;
    final detail = [
      if (title.mediaType != null) words.mediaType(title.mediaType!),
      if (start != null && start.length >= 4) start.substring(0, 4),
      if (episodes != null && episodes > 0) words.episodes(episodes),
      words.status(title.status),
    ].join(' · ');
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!ticked),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Tokens.space2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppCheckbox(
                value: ticked ? CheckValue.checked : CheckValue.empty,
                onChanged: (value) => onChanged(value == CheckValue.checked),
              ),
              const SizedBox(width: Tokens.space3),
              if (cover != null) ...[
                cover!(title, Tokens.listCoverWidth),
                const SizedBox(width: Tokens.space3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(Tokens.ink),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption(Tokens.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
