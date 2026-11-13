import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

class Hairline extends StatelessWidget {
  const Hairline({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 1, child: ColoredBox(color: Tokens.line));
}
