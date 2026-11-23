import 'package:flutter/widgets.dart';

import '../../design/tokens.dart';
import 'detail_heading.dart';

/// A smaller named block inside a part: a muted heading, then its content.
class DetailBlock extends StatelessWidget {
  const DetailBlock({
    super.key,
    required this.title,
    required this.child,
    this.last = false,
  });

  final String title;
  final Widget child;

  /// The last block in its column, with no gap under it.
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : Tokens.space5),
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
