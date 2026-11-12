import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/score_star.dart';
import 'pressable.dart';

class StarRating extends StatefulWidget {
  const StarRating({
    super.key,
    required this.value,
    required this.onChanged,
    required this.labelFor,
    required this.clearLabel,
    this.spread = false,
  });

  static const count = 10;

  final int? value;
  final ValueChanged<int?>? onChanged;
  final String Function(int score) labelFor;
  final String clearLabel;

  final bool spread;

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  int? _hover;

  Widget _cell(Widget star) =>
      widget.spread ? Expanded(child: Center(child: star)) : star;

  @override
  Widget build(BuildContext context) {
    final hover = _hover;
    final clearing = hover != null && hover == widget.value;
    final lit = clearing ? 0 : (hover ?? widget.value ?? 0);
    final caption = hover != null
        ? (clearing ? widget.clearLabel : '$hover')
        : (widget.value != null ? '${widget.value}' : '');
    return MouseRegion(
      onExit: (_) => setState(() => _hover = null),
      child: Row(
        mainAxisSize: widget.spread ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var score = 1; score <= StarRating.count; score++)
            _cell(
              MouseRegion(
                onEnter: (_) => setState(() => _hover = score),
                child: Semantics(
                  label: widget.labelFor(score),
                  child: Pressable(
                    onPressed: widget.onChanged == null
                        ? null
                        : () => widget.onChanged!(
                            score == widget.value ? null : score,
                          ),
                    builder: (context, state) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Tokens.space1,
                        vertical: Tokens.space2,
                      ),
                      child: ScoreStar(
                        size: Tokens.iconSize,
                        color: score <= lit ? Tokens.amber : Tokens.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: Tokens.space2),
          // every caption sits in the stack, so the width never moves under the pointer
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              for (final text in [widget.clearLabel, '10'])
                Opacity(
                  opacity: 0,
                  child: Text(text, style: AppText.label(Tokens.ink)),
                ),
              Text(
                caption,
                style: AppText.label(
                  hover != null ? Tokens.amber : Tokens.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
