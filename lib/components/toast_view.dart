import 'package:flutter/widgets.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/app_icons.dart';
import 'quiet_icon_button.dart';
import 'text_action.dart';

/// One toast: a message with an X, an optional amber action beside it, and an
/// optional [footer] row under them (the review toast puts its stars and the
/// Review button there). It only draws; the host decides what shows and when.
class ToastView extends StatelessWidget {
  const ToastView({
    super.key,
    required this.message,
    required this.onClose,
    required this.closeLabel,
    this.actionLabel,
    this.onAction,
    this.footer,
  });

  final String message;
  final VoidCallback onClose;

  /// What a screen reader says for the X.
  final String closeLabel;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Tokens.toastMaxWidth),
      child: ColoredBox(
        color: Tokens.surface,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: Tokens.space4,
                        top: Tokens.space2,
                        bottom: Tokens.space2,
                      ),
                      // announced when it appears, without taking focus
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          message,
                          style: AppText.label(Tokens.ink)
                              .copyWith(height: 1.3),
                        ),
                      ),
                    ),
                  ),
                  if (actionLabel != null)
                    TextAction(label: actionLabel!, onPressed: onAction),
                  QuietIconButton(
                    icon: AppIcons.dropped,
                    label: closeLabel,
                    onPressed: onClose,
                  ),
                ],
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: Tokens.space3,
                    right: Tokens.space1,
                  ),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
