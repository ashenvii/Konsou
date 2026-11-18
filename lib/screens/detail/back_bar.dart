import 'package:flutter/widgets.dart';

import '../../components/hover_mark.dart';
import '../../components/one_line_text.dart';
import '../../components/page_frame.dart';
import '../../components/pressable.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';

/// The back button at the top of the Detail page, floating over the content.
/// Plain, it is only the button. Once the page scrolls past the title, a fade
/// from the top comes in behind it, the button turns into a white box with a
/// dark arrow, and the title appears beside it, with [status] at the right.
/// [fade] runs from 0 to 1 over that change; [scrolled] is whether it has
/// begun.
class BackBar extends StatelessWidget {
  const BackBar({
    super.key,
    required this.title,
    required this.scrolled,
    required this.onBack,
    required this.onTitle,
    this.status,
    double? fade,
  }) : fade = fade ?? (scrolled ? 1 : 0);

  final String title;
  final bool scrolled;
  final double fade;
  final VoidCallback onBack;

  /// The user's status button, shown once the header has scrolled away.
  final Widget? status;

  /// The scrolled title was clicked: back to the top.
  final VoidCallback onTitle;

  static const height = Tokens.controlHeight + 2 * PageFrame.edge;

  @override
  Widget build(BuildContext context) {
    // the box keeps the page colour until it turns white
    final boxColor = Color.lerp(Tokens.ground, Tokens.ink, fade)!;
    final arrowColor = Color.lerp(Tokens.ink, Tokens.ground, fade)!;
    return SizedBox(
      height: height + 2 * Tokens.space5,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: fade,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Tokens.ground,
                        Tokens.ground,
                        Tokens.ground.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: PageFrame.edge,
            right: PageFrame.edge,
            top: PageFrame.edge,
            child: Row(
              children: [
                Pressable(
                  label: 'Back',
                  onPressed: onBack,
                  focusColor: fade > 0.5 ? Tokens.ground : Tokens.ink,
                  builder: (context, state) => HoverMark(
                    on: !scrolled && state.hovered,
                    child: Container(
                      width: Tokens.controlHeight,
                      height: Tokens.controlHeight,
                      alignment: Alignment.center,
                      color: boxColor,
                      child: AppIcon(
                        AppIcons.arrowLeft,
                        size: Tokens.iconSize,
                        color: arrowColor,
                      ),
                    ),
                  ),
                ),
                if (scrolled) const SizedBox(width: Tokens.space2),
                if (scrolled)
                  Flexible(
                    child: Opacity(
                      opacity: fade,
                      child: Pressable(
                        label: title,
                        onPressed: onTitle,
                        builder: (context, state) => HoverMark(
                          on: state.hovered,
                          child: Container(
                            height: Tokens.controlHeight,
                            color: boxColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: Tokens.space3,
                            ),
                            child: Center(
                              widthFactor: 1,
                              child: OneLineText(
                                title,
                                style: AppText.label(arrowColor, bold: true),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (scrolled && status != null) ...[
                  const Spacer(),
                  const SizedBox(width: Tokens.space4),
                  Opacity(opacity: fade, child: status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
