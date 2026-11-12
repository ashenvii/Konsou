import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import 'floating_panel.dart';
import '../icons/app_icons.dart';
import 'icon_square_button.dart';

class ToastView extends StatelessWidget {
  const ToastView({
    super.key,
    required this.message,
    required this.onClose,
    required this.closeLabel,
    this.actions = const [],
    this.footer,
    this.timer,
    this.wide = false,
  });

  final String message;
  final VoidCallback onClose;

  final String closeLabel;
  final List<Widget> actions;
  final Widget? footer;

  final Widget? timer;

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Tokens.space4,
                  top: Tokens.space3,
                  bottom: Tokens.space3,
                ),
                // announced when it appears, without taking focus
                child: Semantics(
                  liveRegion: true,
                  child: Text(message, style: AppText.label(Tokens.ink)),
                ),
              ),
            ),
            const SizedBox(width: Tokens.space3),
            ...actions,
            IconSquareButton(
              icon: AppIcons.dropped,
              label: closeLabel,
              onPressed: onClose,
            ),
          ],
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(
              left: Tokens.space4,
              right: Tokens.space4,
              bottom: Tokens.space2,
            ),
            child: footer,
          ),
        ?timer,
      ],
    );
    // the layer holds the width to toastMaxWidth
    return FloatingPanel(child: wide ? body : IntrinsicWidth(child: body));
  }
}
