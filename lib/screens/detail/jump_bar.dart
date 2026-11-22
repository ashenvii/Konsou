import 'package:flutter/widgets.dart';

import '../../app/cover_view.dart';
import '../../components/app_menu.dart';
import '../../components/app_popover.dart';
import '../../components/menu_chevron.dart';
import '../../components/cover_image.dart';
import '../../components/motion.dart';
import '../../components/one_line_text.dart';
import '../../components/page_frame.dart';
import '../../components/pressable.dart';
import '../../components/raised_key.dart';
import '../../components/solid_icon_button.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/app_icons.dart';

/// The back button, a white key with a dark arrow. It floats over the top of
/// the Detail page and moves into the [JumpBar] at the top, the same either
/// place.
class DetailBackButton extends StatelessWidget {
  const DetailBackButton({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SolidIconButton(
    icon: AppIcons.arrowLeft,
    label: 'Back',
    onPressed: onBack,
  );
}

/// The Detail page's section names in a row under its top, each jumping to
/// its part of the page, the one in view underlined in cyan. It sticks to
/// the top as the page scrolls, and once [stuck] the back button, a small
/// cover and the title slide in at its left and [status] at its right, so it
/// becomes the page's bar. Names that do not fit go under More.
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

  // the bar's fill runs this far up under the top above it, so a pixel of
  // rounding between the two while scrolling shows chassis, not the page
  // behind
  static const _underlap = Tokens.space2;

  static const _miniCover = Tokens.space5;
  static const _titleWidth = Tokens.space5 * 10;

  @override
  Widget build(BuildContext context) {
    final duration = chooseMotionDuration(context, Tokens.motionQuick);
    final bar = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: PageFrame.edge),
      decoration: BoxDecoration(
        // under the art on the page's ground; at the top, a line between it
        // and the page scrolling under it
        color: Tokens.chassisTop,
        border: Border(
          bottom: BorderSide(color: stuck ? Tokens.line : Tokens.edgeLight),
        ),
      ),
      child: Row(
        children: [
          // the page's own bar slides in from the left once it is at the top
          TweenAnimationBuilder<double>(
            tween: Tween(end: stuck ? 1 : 0),
            duration: duration,
            curve: Curves.easeOut,
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
                        DetailBackButton(onBack: onBack),
                        const SizedBox(width: Tokens.space2),
                        _TitleButton(
                          title: title,
                          malId: hideCover ? null : malId,
                          width: _titleWidth,
                          coverWidth: _miniCover,
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: 0,
          right: 0,
          top: -_underlap,
          height: _underlap,
          child: ColoredBox(color: Tokens.chassisTop),
        ),
        bar,
      ],
    );
  }
}

class _TitleButton extends StatelessWidget {
  const _TitleButton({
    required this.title,
    required this.malId,
    required this.width,
    required this.coverWidth,
    required this.onPressed,
  });

  final String title;
  final int? malId;
  final double width;
  final double coverWidth;
  final VoidCallback onPressed;

  /// The title as a key: the back button's white key, wider, with the small
  /// cover at its left edge.
  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: title,
      onPressed: onPressed,
      focusColor: Tokens.ground,
      builder: (context, state) => Transform.translate(
        offset: keyLift,
        child: Container(
          width: width,
          height: Tokens.controlHeight,
          decoration: solidKeyDecoration(hovered: state.hovered),
          child: ClipRRect(
            borderRadius: Tokens.keyCorners,
            child: Row(
              children: [
                SizedBox(
                  width: coverWidth,
                  height: Tokens.controlHeight,
                  child: OverflowBox(
                    maxHeight: CoverImage.heightFor(coverWidth),
                    child: CoverView(malId: malId, width: coverWidth),
                  ),
                ),
                const SizedBox(width: Tokens.space2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: Tokens.space3),
                    child: OneLineText(
                      title,
                      style: AppText.label(Tokens.ground, bold: true),
                    ),
                  ),
                ),
              ],
            ),
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
        text: TextSpan(text: label, style: AppText.label(Tokens.ink)),
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
                  _JumpTab(
                    label: labels[i],
                    selected: i == active,
                    onPressed: () => onJump(i),
                  ),
                if (rest.isNotEmpty)
                  AppPopover(
                    gap: Tokens.space1,
                    builder: (context, handle) => _JumpTab(
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

/// One name in the jump bar: muted, brighter under the pointer, and the one
/// in view in full ink over a cyan line.
class _JumpTab extends StatelessWidget {
  const _JumpTab({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.opensMenu = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final bool opensMenu;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      selected: selected,
      onPressed: onPressed,
      builder: (context, state) {
        final ink = selected || state.hovered || state.focused
            ? Tokens.ink
            : Tokens.inkMuted;
        return Container(
          height: Tokens.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? Tokens.pop
                    : Tokens.ground.withValues(alpha: 0),
                width: Tokens.hoverEdge,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppText.label(ink)),
              if (opensMenu) MenuChevron(color: ink),
            ],
          ),
        );
      },
    );
  }
}
