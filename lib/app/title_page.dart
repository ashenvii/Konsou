import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// A page that shows only its name, for the places not built yet.
class TitlePage extends StatelessWidget {
  const TitlePage(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Tokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: Tokens.sans,
              fontWeight: FontWeight.w700,
              fontSize: Tokens.text5,
              color: Tokens.ink,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: Tokens.space4),
            action!,
          ],
        ],
      ),
    );
  }
}
