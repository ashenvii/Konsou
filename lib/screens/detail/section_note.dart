import 'package:flutter/widgets.dart';

import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import 'detail_section.dart';

/// A quiet note for a [DetailSection]'s heading.
class SectionNote extends StatelessWidget {
  const SectionNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.right,
    style: AppText.caption(Tokens.inkMuted).wrapped,
  );
}
