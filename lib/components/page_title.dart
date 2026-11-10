import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';

/// A page's name, as tall as a control so it lines up with the buttons beside
/// it, its text centred in that height.
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Tokens.controlHeight,
      child: Center(
        widthFactor: 1,
        child: Text(
          title,
          maxLines: 1,
          softWrap: false,
          style: AppText.heading,
        ),
      ),
    );
  }
}
