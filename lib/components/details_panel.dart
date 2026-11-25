import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'floating_panel.dart';

/// The details popover's panel: [Tokens.popoverWidth] wide, [Tokens.space5]
/// in, on the raised fill with the soft shadow.
class DetailsPanel extends StatelessWidget {
  const DetailsPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => FloatingPanel(
    child: SizedBox(
      width: Tokens.popoverWidth,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space5),
        child: child,
      ),
    ),
  );
}
