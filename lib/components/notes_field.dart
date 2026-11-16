import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'countdown.dart';
import 'field_text.dart';

/// A box for free text that saves itself: a moment after typing stops, when
/// it loses focus, and when it leaves the screen. There is no Save button.
class NotesField extends StatefulWidget {
  const NotesField({
    super.key,
    required this.initial,
    required this.placeholder,
    required this.onSave,
  });

  final String initial;
  final String placeholder;
  final ValueChanged<String> onSave;

  static const saveAfter = Duration(seconds: 1);

  @override
  State<NotesField> createState() => NotesFieldState();
}

class NotesFieldState extends State<NotesField> {
  late final _controller = TextEditingController(text: widget.initial);
  late final Countdown _wait = Countdown(onDone: flush);
  final _focus = FocusNode();
  late String _saved = widget.initial;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() {
    if (!_focus.hasFocus) flush();
    setState(() {});
  }

  void _changed(String text) => _wait.start(NotesField.saveAfter);

  /// Saves what is typed now, if it is not saved yet.
  void flush() {
    _wait.cancel();
    final text = _controller.text;
    if (text == _saved) return;
    _saved = text;
    widget.onSave(text);
  }

  @override
  void dispose() {
    flush();
    _wait.dispose();
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus.requestFocus,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: _focus.hasFocus
                ? Border.all(color: Tokens.ink, width: Tokens.focusRing)
                : null,
          ),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: Tokens.controlHeight * 3,
            ),
            padding: const EdgeInsets.all(Tokens.space3),
            color: Tokens.surface,
            child: FieldText(
              controller: _controller,
              focusNode: _focus,
              placeholder: widget.placeholder,
              style: AppText.paragraph(Tokens.ink),
              multiline: true,
              onChanged: _changed,
            ),
          ),
        ),
      ),
    );
  }
}
