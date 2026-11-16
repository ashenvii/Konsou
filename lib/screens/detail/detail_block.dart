import 'package:flutter/widgets.dart';

import '../../design/text_styles.dart';
import '../../design/tokens.dart';

/// One named part of a tab: a small heading, then its content. Every part of
/// the Detail page's tabs is one of these, so a new part lines up with the
/// rest.
class DetailBlock extends StatelessWidget {
  const DetailBlock({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: AppText.label(Tokens.inkSoft, bold: true),
            ),
          ),
          const SizedBox(height: Tokens.space3),
          child,
        ],
      ),
    );
  }
}
