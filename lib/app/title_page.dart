import 'package:flutter/widgets.dart';

import '../components/page_frame.dart';
import '../components/page_title.dart';
import '../design/tokens.dart';

/// A page that shows only its name, for the places not built yet.
class TitlePage extends StatelessWidget {
  const TitlePage(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PageFrame.top,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle(title),
          if (action != null) ...[
            const SizedBox(height: Tokens.space4),
            action!,
          ],
        ],
      ),
    );
  }
}
