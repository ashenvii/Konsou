import 'dart:async';

import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'hover_mark.dart';
import 'pressable.dart';

/// A button that is only its text at rest. Every so often one live-color
/// sweep crosses it to say it can be clicked, and on hover its shape shows
/// with the app's live edge. Under reduced motion the sweep does not run.
class SweepButton extends StatefulWidget {
  const SweepButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  /// Time between one sweep starting and the next.
  static const gap = Duration(seconds: 6);

  /// How long one sweep takes to cross the button.
  static const sweepTime = Duration(milliseconds: 720);

  /// The first sweep, soon after the button appears.
  static const firstSweep = Duration(milliseconds: 600);

  @override
  State<SweepButton> createState() => _SweepButtonState();
}

class _SweepButtonState extends State<SweepButton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: SweepButton.sweepTime,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SweepButton.firstSweep, _sweep);
  }

  void _sweep() {
    if (!mounted) return;
    if (!MediaQuery.disableAnimationsOf(context)) _controller.forward(from: 0);
    _timer = Timer(SweepButton.gap, _sweep);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: widget.label,
      onPressed: widget.onPressed,
      builder: (context, state) => HoverMark(
        on: state.hovered,
        child: SizedBox(
          height: Tokens.controlHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  softWrap: false,
                  style: AppText.label(
                    state.hovered ? Tokens.ink : Tokens.inkSoft,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => FractionalTranslation(
                        // from fully left of the button to fully right of it
                        translation: Offset(-1 + 2 * _controller.value, 0),
                        child: _band,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _band = DecoratedBox(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Tokens.mint.withValues(alpha: 0),
        Tokens.mint.withValues(alpha: 0.38),
        Tokens.mint.withValues(alpha: 0),
      ],
      stops: const [0.3, 0.5, 0.7],
    ),
  ),
);
