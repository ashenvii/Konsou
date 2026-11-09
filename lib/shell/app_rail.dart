import 'package:flutter/widgets.dart';

import '../components/pressable.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../icons/icon_def.dart';

/// One place the rail can go.
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

/// Top to bottom. Settings sits at the bottom, apart from the rest.
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

/// The left rail: icons only, the active one a filled amber square.
class AppRail extends StatelessWidget {
  const AppRail({super.key, required this.location, required this.onSelect});

  /// The path of the page showing now.
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
      child: Semantics(
        label: destination.label,
        child: Pressable(
          onPressed: () => onSelect(destination.path),
          selected: active,
          focusColor: active ? Tokens.ground : Tokens.ink,
          builder: (context, state) => ColoredBox(
            color: active ? Tokens.amber : Tokens.ground,
            child: SizedBox.square(
              dimension: Tokens.railItemSize,
              child: Center(
                child: AppIcon(
                  destination.icon,
                  size: Tokens.railIconSize,
                  color: active
                      ? Tokens.ground
                      : (state.hovered ? Tokens.ink : Tokens.inkMuted),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
