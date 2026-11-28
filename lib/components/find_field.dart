import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'close_on_escape.dart';
import 'field_text.dart';
import 'sunk_well.dart';

/// The small Find text field with its close key.
class FindField extends StatefulWidget {
  const FindField({
    super.key,
    required this.initial,
    required this.placeholder,
    required this.onChanged,
    required this.onClose,
    this.width = Tokens.findFieldWidth,
    this.closeWhenEmpty = true,
    this.autofocus = true,
  });

  final String initial;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  final double width;

  /// Leaving it empty closes it. Off for a box that stays on the page.
  final bool closeWhenEmpty;
  final bool autofocus;

  @override
  State<FindField> createState() => _FindFieldState();
}

class _FindFieldState extends State<FindField> {
  late final _controller = TextEditingController(text: widget.initial);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_leftEmpty);
    _focus.addListener(_ring);
  }

  void _ring() => setState(() {});

  void _leftEmpty() {
    if (widget.closeWhenEmpty && !_focus.hasFocus && _controller.text.isEmpty) {
      widget.onClose();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_leftEmpty);
    _focus.removeListener(_ring);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CloseOnEscape(
      onClose: widget.onClose,
      // a well; its lip hangs below, so the well is a lip short of the slot
      child: SunkWell(
        width: widget.width,
        height: Tokens.controlHeight - SunkWell.lip,
        focused: _focus.hasFocus,
        child: Row(
          children: [
            const AppIcon(
              AppIcons.search,
              size: Tokens.iconSize,
              color: Tokens.inkSoft,
            ),
            const SizedBox(width: Tokens.space2),
            Expanded(
              child: FieldText(
                controller: _controller,
                focusNode: _focus,
                placeholder: widget.placeholder,
                style: AppText.label(Tokens.ink),
                autofocus: widget.autofocus,
                onChanged: widget.onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
