import 'package:flutter/widgets.dart';

import '../components/hover_mark.dart';
import '../components/hover_tip.dart';
import '../components/pressable.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../icons/icon_def.dart';

class RailDestination {
  const RailDestination(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconDef icon;
}

const libraryPath = '/';
const watchingPath = '/watching';
const discoverPath = '/discover';
const schedulePath = '/schedule';
const settingsPath = '/settings';

const railDestinations = [
  RailDestination(libraryPath, 'Library', AppIcons.library),
  RailDestination(watchingPath, 'Watching', AppIcons.watching),
  RailDestination(discoverPath, 'Discover', AppIcons.discover),
  RailDestination(schedulePath, 'Schedule', AppIcons.schedule),
];
const settingsDestination = RailDestination(
  settingsPath,
  'Settings',
  AppIcons.settings,
);

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
                          child: AppIcon(
                            destination.icon,
                            size: Tokens.iconSize,
                            color: active
                                ? Tokens.amber
                                : (state.hovered
                                      ? Tokens.ink
                                      : Tokens.inkMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (active)
                    const Positioned(
                      right: 0,
                      top: Tokens.space2,
                      bottom: Tokens.space2,
                      width: Tokens.hoverEdge,
                      child: ColoredBox(color: Tokens.amber),
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
