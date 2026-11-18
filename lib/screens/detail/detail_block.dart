import 'package:flutter/widgets.dart';

import '../../design/text_styles.dart';
import '../../design/tokens.dart';

/// One named part of the Detail page: a small heading, then its content.
/// Every part of the page is one of these, so a new part lines up with the
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
          DetailHeading(title),
          const SizedBox(height: Tokens.space3),
          child,
        ],
      ),
    );
  }
}

/// The small heading over a part of the Detail page.
class DetailHeading extends StatelessWidget {
  const DetailHeading(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(title, style: AppText.label(Tokens.inkSoft, bold: true)),
  );
}
