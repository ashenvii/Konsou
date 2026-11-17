import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

/// The typing part of a field: the text, with the placeholder under it until
/// something is typed. The box around it belongs to the field.
class FieldText extends StatelessWidget {
  const FieldText({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.style,
    // soft ink: muted ink on the surface fill is under 4.5:1
    this.placeholderColor = Tokens.inkSoft,
    this.cursorColor = Tokens.amber,
    this.autofocus = false,
    this.multiline = false,
    this.onChanged,
    this.onSubmitted,
    this.onTapOutside,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final TextStyle style;
  final Color placeholderColor;
  final Color cursorColor;
  final bool autofocus;
  final bool multiline;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TapRegionCallback? onTapOutside;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: multiline
          ? AlignmentDirectional.topStart
          : Alignment.centerLeft,
      children: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? Text(
                  placeholder,
                  maxLines: multiline ? null : 1,
                  softWrap: multiline,
                  style: style.copyWith(color: placeholderColor),
                )
              : const SizedBox.shrink(),
        ),
        EditableText(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          style: style,
          cursorColor: cursorColor,
          backgroundCursorColor: Tokens.inkMuted,
          selectionColor: Tokens.inkMuted,
          maxLines: multiline ? null : 1,
          keyboardType: multiline ? TextInputType.multiline : null,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTapOutside: onTapOutside,
          inputFormatters: inputFormatters,
          textAlign: textAlign,
        ),
      ],
    );
  }
}
