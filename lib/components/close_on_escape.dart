import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class CloseOnEscape extends StatelessWidget {
  const CloseOnEscape({super.key, required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              onClose();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
