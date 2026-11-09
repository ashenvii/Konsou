import 'package:flutter/widgets.dart';

import '../../components/pressable.dart';

/// What a Library row or card does under the pointer: a click opens it, a
/// right click or a long press asks for its menu at that position.
class RowTapArea extends StatelessWidget {
  const RowTapArea({
    super.key,
    required this.onOpen,
    required this.onContextMenu,
    required this.builder,
  });

  final VoidCallback onOpen;

  /// The position in window coordinates.
  final ValueChanged<Offset> onContextMenu;
  final Widget Function(BuildContext context, PressState state) builder;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onOpen,
      builder: (context, state) => GestureDetector(
        onSecondaryTapDown: (details) => onContextMenu(details.globalPosition),
        onLongPressStart: (details) => onContextMenu(details.globalPosition),
        child: builder(context, state),
      ),
    );
  }
}
