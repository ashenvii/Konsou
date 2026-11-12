import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../library/earlier_titles.dart';
import 'app_button.dart';
import 'app_checkbox.dart';

/// The words the review shows. The screen supplies them, so they live in one
/// file.
class EarlierReviewWords {
  const EarlierReviewWords({
    required this.extrasHeading,
    required this.notNow,
    required this.mark,
  });

  final String extrasHeading;
  final String notNow;
  final String Function(int count) mark;
}

/// The review of earlier titles after a finish: the earlier stories ticked,
/// the extras unticked under their own heading, then Mark and Not now.
/// [titles] come stories first.
class EarlierReview extends StatefulWidget {
  const EarlierReview({
    super.key,
    required this.titles,
    required this.words,
    required this.onMark,
    required this.onNotNow,
  });

  final List<EarlierTitle> titles;
  final EarlierReviewWords words;
  final ValueChanged<List<EarlierTitle>> onMark;
  final VoidCallback onNotNow;

  @override
  State<EarlierReview> createState() => _EarlierReviewState();
}

class _EarlierReviewState extends State<EarlierReview> {
  late final Set<int> _ticked = {
    for (final title in widget.titles)
      if (!title.isExtra) title.malId,
  };

  @override
  Widget build(BuildContext context) {
    final titles = widget.titles;
    final firstExtra = titles.indexWhere((title) => title.isExtra);
    final chosen = [
      for (final title in titles)
        if (_ticked.contains(title.malId)) title,
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Tokens.toastMaxWidth),
      child: ColoredBox(
        color: Tokens.surface,
        child: Padding(
          padding: const EdgeInsets.all(Tokens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, title) in titles.indexed) ...[
                        if (index == firstExtra)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: Tokens.space2,
                              bottom: Tokens.space1,
                            ),
                            child: Text(
                              widget.words.extrasHeading,
                              style: AppText.caption(Tokens.inkSoft),
                            ),
                          ),
                        _TitleRow(
                          title: title,
                          ticked: _ticked.contains(title.malId),
                          onChanged: (on) => setState(() {
                            on
                                ? _ticked.add(title.malId)
                                : _ticked.remove(title.malId);
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Tokens.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: widget.words.notNow,
                    kind: ButtonKind.secondary,
                    onPressed: widget.onNotNow,
                  ),
                  const SizedBox(width: Tokens.space2),
                  AppButton(
                    label: widget.words.mark(chosen.length),
                    onPressed: chosen.isEmpty
                        ? null
                        : () => widget.onMark(chosen),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.ticked,
    required this.onChanged,
  });

  final EarlierTitle title;
  final bool ticked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (title.mediaType != null) title.mediaType!.toUpperCase(),
      if (title.startDate != null && title.startDate!.length >= 4)
        title.startDate!.substring(0, 4),
    ].join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tokens.space1),
      child: Row(
        children: [
          AppCheckbox(
            value: ticked ? CheckValue.checked : CheckValue.empty,
            onChanged: (value) => onChanged(value == CheckValue.checked),
          ),
          const SizedBox(width: Tokens.space3),
          Expanded(
            child: Text(
              title.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(Tokens.ink),
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(width: Tokens.space3),
            Text(detail, style: AppText.caption(Tokens.inkSoft)),
          ],
        ],
      ),
    );
  }
}
