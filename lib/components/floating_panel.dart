import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

class FloatingPanel extends StatelessWidget {
  const FloatingPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Tokens.raised,
        boxShadow: [
          BoxShadow(
            color: Tokens.shadow,
            blurRadius: Tokens.shadowBlur,
            offset: Offset(0, Tokens.shadowDrop),
          ),
        ],
      ),
      child: child,
    );
  }
}
