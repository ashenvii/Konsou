import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'hover_mark.dart';
import 'pressable.dart';

/// A row that does one thing when clicked, such as opening a link: the hover
/// mark under the pointer and on focus, and [children] laid out in a line,
/// built knowing whether the row is lit.
class LinkRow extends StatelessWidget {
  const LinkRow({
    super.key,
    required this.label,
    required this.onPressed,
    required this.children,
  });

  final String label;
  final VoidCallback onPressed;
  final List<Widget> Function(bool lit) children;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      onPressed: onPressed,
      builder: (context, state) {
        final lit = state.hovered || state.focused;
        return HoverMark(
          on: lit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Tokens.space2),
            child: Row(children: children(lit)),
          ),
        );
      },
    );
  }
}
