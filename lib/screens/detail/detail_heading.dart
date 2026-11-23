import 'package:flutter/widgets.dart';

import '../../design/text_styles.dart';
import '../../design/tokens.dart';

/// The small muted heading over a block inside a part.
class DetailHeading extends StatelessWidget {
  const DetailHeading(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      title,
      style: AppText.caption(Tokens.inkMuted)
          .copyWith(fontWeight: FontWeight.w700),
    ),
  );
}
