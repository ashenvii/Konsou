import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/score_star.dart';
import 'pressable.dart';

/// Ten stars in a row for a score from 1 to 10. A click sets the score;
/// clicking the current score clears it (reports null). Hovering lights the
/// stars up to the one under the pointer, and the number beside them shows
/// what a click would set; over the current score it says [clearLabel], since
/// a click there clears it. With no score and no hover it shows [hint]. The
/// words come from the screen. [labelFor] is what a screen reader says for each
/// star.
class StarRating extends StatefulWidget {
  const StarRating({
    super.key,
    required this.value,
    required this.onChanged,
    required this.labelFor,
    required this.hint,
    required this.clearLabel,
  });

  static const count = 10;

  final int? value;
  final ValueChanged<int?>? onChanged;
  final String Function(int score) labelFor;
  final String hint;
  final String clearLabel;

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final hover = _hover;
    final clearing = hover != null && hover == widget.value;
    final lit = clearing ? 0 : (hover ?? widget.value ?? 0);
    final caption = hover != null
        ? (clearing ? widget.clearLabel : '$hover')
        : (widget.value != null ? '${widget.value}' : widget.hint);
    return MouseRegion(
      onExit: (_) => setState(() => _hover = null),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var score = 1; score <= StarRating.count; score++)
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
          const SizedBox(width: Tokens.space2),
          Text(
            caption,
            style: AppText.label(hover != null ? Tokens.amber : Tokens.inkSoft),
          ),
        ],
      ),
    );
  }
}
