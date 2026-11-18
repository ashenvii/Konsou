import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/app_menu.dart';
import '../../components/app_popover.dart';
import '../../components/app_tab.dart';
import '../../components/cover_image.dart';
import '../../components/hover_mark.dart';
import '../../components/motion.dart';
import '../../components/one_line_text.dart';
import '../../components/page_frame.dart';
import '../../components/pressable.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/app_icon.dart';
import '../../icons/app_icons.dart';

/// The back button, square. It floats over the top of the Detail page on the
/// page's ground, and turns white with a dark arrow as it moves into the
/// [JumpBar] at the top; [white] runs from 0 to 1 over that change.
class DetailBackButton extends StatelessWidget {
  const DetailBackButton({super.key, required this.onBack, this.white = 0});

  final VoidCallback onBack;
  final double white;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: 'Back',
      onPressed: onBack,
      focusColor: white > 0.5 ? Tokens.ground : Tokens.ink,
      builder: (context, state) => HoverMark(
        on: state.hovered && white < 0.5,
        child: Container(
          width: Tokens.controlHeight,
          height: Tokens.controlHeight,
          alignment: Alignment.center,
          color: Color.lerp(Tokens.ground, Tokens.ink, white),
          child: AppIcon(
            AppIcons.arrowLeft,
            size: Tokens.iconSize,
            color: Color.lerp(
              state.hovered ? Tokens.ink : Tokens.inkSoft,
              Tokens.ground,
              white,
            )!,
          ),
        ),
      ),
    );
  }
}

/// The Detail page's section names in a row under its top, each jumping to
/// its part of the page, the one in view filled amber. It sticks to the top
/// as the page scrolls, and once [stuck] the back button, a small cover and
/// the title slide in at its left and [status] at its right, so it becomes
/// the page's bar. Names that do not fit go under More.
class JumpBar extends StatelessWidget {
  const JumpBar({
    super.key,
    required this.title,
    required this.labels,
    required this.active,
    required this.stuck,
    required this.onJump,
    required this.onBack,
    required this.onTop,
    this.malId,
    this.hideCover = false,
    this.status,
  });

  final String title;
  final List<String> labels;
  final int active;
  final bool stuck;
  final ValueChanged<int> onJump;
  final VoidCallback onBack;

  /// The title was clicked: back to the top.
  final VoidCallback onTop;
  final int? malId;

  /// Streamer mode on an adult title: no cover.
  final bool hideCover;
  final Widget? status;

  static const height = Tokens.controlHeight + 2 * Tokens.space2;

  static const _miniCover = Tokens.space5;
  static const _titleWidth = Tokens.space5 * 10;

  @override
  Widget build(BuildContext context) {
    final duration = chooseMotionDuration(context, Tokens.motionQuick);
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: PageFrame.edge),
      decoration: BoxDecoration(
        color: Tokens.ground,
        border: Border(
          bottom: BorderSide(color: stuck ? Tokens.line : Tokens.surface),
        ),
      ),
      child: Row(
        children: [
          // the page's own bar slides in from the left once it is at the top
          TweenAnimationBuilder<double>(
            tween: Tween(end: stuck ? 1 : 0),
            duration: duration,
            curve: Curves.easeOut,
            // the back button and title turn white as they arrive
            builder: (context, share, child) => ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: share,
                child: Opacity(
                  opacity: share,
                  child: ExcludeFocus(
                    excluding: !stuck,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DetailBackButton(onBack: onBack, white: share),
                        const SizedBox(width: Tokens.space2),
                        _TitleButton(
                          title: title,
                          malId: hideCover ? null : malId,
                          width: _titleWidth,
                          coverWidth: _miniCover,
                          white: share,
                          onPressed: onTop,
                        ),
                        const SizedBox(width: Tokens.space4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _Sections(labels: labels, active: active, onJump: onJump),
          ),
          if (status != null)
            AnimatedOpacity(
              opacity: stuck ? 1 : 0,
              duration: duration,
              // hidden until the bar is at the top: no clicks, no focus
              child: IgnorePointer(
                ignoring: !stuck,
                child: ExcludeFocus(
                  excluding: !stuck,
                  child: Padding(
                    padding: const EdgeInsets.only(left: Tokens.space4),
                    child: status,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TitleButton extends StatelessWidget {
  const _TitleButton({
    required this.title,
    required this.malId,
    required this.width,
    required this.coverWidth,
    required this.white,
    required this.onPressed,
  });

  final String title;
  final int? malId;
  final double width;
  final double coverWidth;

  /// From 0 to 1: the box goes from the ground to white, the text to dark.
  final double white;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: title,
      onPressed: onPressed,
      focusColor: white > 0.5 ? Tokens.ground : Tokens.ink,
      builder: (context, state) => HoverMark(
        on: state.hovered,
        child: Container(
          width: width,
          height: Tokens.controlHeight,
          color: Color.lerp(Tokens.ground, Tokens.ink, white),
          padding: const EdgeInsets.only(right: Tokens.space3),
          child: Row(
            children: [
              ClipRect(
                child: SizedBox(
                  width: coverWidth,
                  height: Tokens.controlHeight,
                  child: OverflowBox(
                    maxHeight: CoverImage.heightFor(coverWidth),
                    child: CoverView(malId: malId, width: coverWidth),
                  ),
                ),
              ),
              const SizedBox(width: Tokens.space2),
              Expanded(
                child: OneLineText(
                  title,
                  style: AppText.label(
                    Color.lerp(Tokens.ink, Tokens.ground, white)!,
                    bold: true,
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

/// As many section names as fit, measured at the current text size, and the
/// rest under More.
class _Sections extends StatelessWidget {
  const _Sections({
    required this.labels,
    required this.active,
    required this.onJump,
  });

  final List<String> labels;
  final int active;
  final ValueChanged<int> onJump;

  static const _more = 'More';

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    double widthOf(String label) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: AppText.label(Tokens.ink, bold: true),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final width = painter.width + 2 * Tokens.space4;
      painter.dispose();
      return width;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final widths = [for (final label in labels) widthOf(label)];
        final moreWidth = widthOf(_more) + Tokens.iconSize;
        var shown = labels.length;
        if (widths.fold(0.0, (a, b) => a + b) > constraints.maxWidth) {
          var used = moreWidth;
          shown = 0;
          while (shown < labels.length &&
              used + widths[shown] <= constraints.maxWidth) {
            used += widths[shown];
            shown++;
          }
        }
        final rest = [for (var i = shown; i < labels.length; i++) i];
        // clipped, not spilled, in a window too narrow even for More
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < shown; i++)
                  AppTab(
                    label: labels[i],
                    selected: i == active,
                    onPressed: () => onJump(i),
                  ),
                if (rest.isNotEmpty)
                  AppPopover(
                    gap: Tokens.space1,
                    builder: (context, handle) => AppTab(
                      label: rest.contains(active) ? labels[active] : _more,
                      selected: rest.contains(active),
                      opensMenu: true,
                      onPressed: handle.open,
                    ),
                    popoverBuilder: (context, handle) => AppMenu(
                      entries: [
                        for (final i in rest)
                          MenuEntry(
                            label: labels[i],
                            selected: i == active,
                            onPressed: () {
                              handle.close();
                              onJump(i);
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
