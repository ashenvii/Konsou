import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';

class RowMarker extends ConsumerWidget {
  const RowMarker({
    super.key,
    required this.entryId,
    required this.openMenu,
    required this.child,
  });

  final String entryId;
  final VoidCallback openMenu;
  final Widget child;

  static RowMarker? ofFocus() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context?.getInheritedWidgetOfExactType<_RowScope>()?.marker;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hovered = ref.read(libraryHoveredRowProvider.notifier);
    return MouseRegion(
      onEnter: (_) => hovered.set(entryId),
      onExit: (_) => hovered.clear(entryId),
      child: _RowScope(marker: this, child: child),
    );
  }
}

class _RowScope extends InheritedWidget {
  const _RowScope({required this.marker, required super.child});

  final RowMarker marker;

  @override
  bool updateShouldNotify(_RowScope oldWidget) =>
      oldWidget.marker.entryId != marker.entryId;
}
