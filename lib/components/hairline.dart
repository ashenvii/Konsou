import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// A one pixel divider.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.color = Tokens.line});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 1, child: ColoredBox(color: color));
}
