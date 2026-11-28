import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../components/hover_mark.dart';
import '../components/hover_tip.dart';
import '../components/pressable.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../icons/icon_def.dart';

/// A page the rail opens: route, label and icon.
class RailDestination {
  const RailDestination(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconDef icon;
}

/// Route of the Library.
const libraryPath = '/';
/// Route of Watching.
const watchingPath = '/watching';
/// Route of Discover.
const discoverPath = '/discover';
/// Route of Schedule.
const schedulePath = '/schedule';
/// Route of Settings.
const settingsPath = '/settings';

/// The rail's pages, top to bottom.
const railDestinations = [
  RailDestination(libraryPath, 'Library', AppIcons.library),
  RailDestination(watchingPath, 'Watching', AppIcons.watching),
  RailDestination(discoverPath, 'Discover', AppIcons.discover),
  RailDestination(schedulePath, 'Schedule', AppIcons.schedule),
];
/// Settings, at the foot of the rail.
const settingsDestination = RailDestination(
  settingsPath,
  'Settings',
  AppIcons.settings,
);

/// The left rail of page icons.
class AppRail extends StatelessWidget {
  const AppRail({super.key, required this.location, required this.onSelect});

  final String location;
  final ValueChanged<String> onSelect;

  bool _isActive(String path) =>
      path == libraryPath ? location == libraryPath : location.startsWith(path);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tokens.space2),
      child: Column(
        children: [
          for (final destination in railDestinations)
            _RailItem(
              destination,
              active: _isActive(destination.path),
              onSelect: onSelect,
            ),
          const Spacer(),
          _RailItem(
            settingsDestination,
            active: _isActive(settingsDestination.path),
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem(
    this.destination, {
    required this.active,
    required this.onSelect,
  });

  final RailDestination destination;
  final bool active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.space2),
      child: HoverTip(
        label: destination.label,
        child: Semantics(
          label: destination.label,
          child: Pressable(
            onPressed: () => onSelect(destination.path),
            selected: active,
            builder: (context, state) => SizedBox(
              width: Tokens.railWidth,
              height: Tokens.railItemSize,
              child: Stack(
                children: [
                  Center(
                    child: HoverMark(
                      on: state.hovered,
                      child: SizedBox.square(
                        dimension: Tokens.railItemSize,
                        child: Center(
                          child: active
                              ? _LitIcon(destination.icon)
                              : AppIcon(
                                  destination.icon,
                                  size: Tokens.iconSize,
                                  color: state.hovered
                                      ? Tokens.ink
                                      : Tokens.inkMuted,
                                ),
                        ),
                      ),
                    ),
                  ),
                  // the lit edge on the window side, glowing a little
                  if (active)
                    const Positioned(
                      right: 0,
                      top: Tokens.space2,
                      bottom: Tokens.space2,
                      width: Tokens.litEdge,
                      child: DecoratedBox(
                        key: Key('rail-lit-edge'),
                        decoration: BoxDecoration(
                          color: Tokens.pop,
                          boxShadow: [
                            BoxShadow(
                              color: Tokens.pop,
                              blurRadius: Tokens.lampGlow,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The current page's icon: pop, over a soft blurred copy of itself, the way a
/// lit key glows. One small blur, only ever on one icon, drawn once and kept
/// while the rest of the rail repaints for hover.
class _LitIcon extends StatelessWidget {
  const _LitIcon(this.icon);

  final IconDef icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: Tokens.ledGlow / 2,
              sigmaY: Tokens.ledGlow / 2,
            ),
            child: AppIcon(
              icon,
              size: Tokens.iconSize,
              color: Tokens.pop.withValues(alpha: 0.4),
            ),
          ),
        ),
        AppIcon(icon, size: Tokens.iconSize, color: Tokens.pop),
      ],
    );
  }
}
