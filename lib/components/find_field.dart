import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'close_on_escape.dart';

class FindField extends StatefulWidget {
  const FindField({
    super.key,
    required this.initial,
    required this.placeholder,
    required this.onChanged,
    required this.onClose,
  });

  final String initial;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

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
    _controller.addListener(() => setState(() {}));
  }

  void _leftEmpty() {
    if (!_focus.hasFocus && _controller.text.isEmpty) widget.onClose();
  }

  @override
  void dispose() {
    _focus.removeListener(_leftEmpty);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppText.label(Tokens.ink);
    return CloseOnEscape(
      onClose: widget.onClose,
      child: Container(
        width: Tokens.findFieldWidth,
        height: Tokens.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
        color: Tokens.surface,
        child: Row(
          children: [
            const AppIcon(
              AppIcons.search,
              size: Tokens.iconSize,
              color: Tokens.inkSoft,
            ),
            const SizedBox(width: Tokens.space2),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (_controller.text.isEmpty)
                    Text(
                      widget.placeholder,
                      maxLines: 1,
                      softWrap: false,
                      // soft ink: muted ink on the surface fill is under 4.5:1
                      style: AppText.label(Tokens.inkSoft),
                    ),
                  EditableText(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: true,
                    style: style,
                    cursorColor: Tokens.amber,
                    backgroundCursorColor: Tokens.inkMuted,
                    selectionColor: Tokens.inkMuted,
                    maxLines: 1,
                    onChanged: widget.onChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
