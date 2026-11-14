import 'package:flutter/services.dart';

import '../design/tokens.dart';

const maximizeButtonChannel = MethodChannel('konsou/window');

/// What Windows says the pointer is doing to the maximize button.
enum MaximizeButtonState { none, hovered, pressed }

/// Tells the runner where the maximize button is. Windows then treats it as
/// the window's own maximize button and shows Snap Layouts over it. From then
/// on its hover and click come from Windows, not from Flutter.
Future<void> linkMaximizeButton() => maximizeButtonChannel.invokeMethod(
  'setMaximizeButton',
  {
    'width': Tokens.windowButtonWidth,
    'height': Tokens.barHeight,
    // the close button sits between it and the window's edge
    'rightInset': Tokens.windowButtonWidth,
    'resizeEdge': Tokens.resizeEdge,
  },
);

void listenToMaximizeButton(ValueChanged<MaximizeButtonState>? onChange) {
  maximizeButtonChannel.setMethodCallHandler(
    onChange == null
        ? null
        : (call) async {
            if (call.method != 'maximizeButtonState') return;
            onChange(MaximizeButtonState.values[call.arguments as int]);
          },
  );
}
