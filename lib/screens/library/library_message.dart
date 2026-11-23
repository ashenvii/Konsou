import 'package:flutter/widgets.dart';

import '../../components/page_frame.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';

class LibraryMessage extends StatelessWidget {
  const LibraryMessage(this.text, {super.key, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PageFrame.content,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Tokens.space5),
          Text(text, style: AppText.label(Tokens.inkSoft)),
          if (action != null) ...[
            const SizedBox(height: Tokens.space4),
            action!,
          ],
        ],
      ),
    );
  }
}
