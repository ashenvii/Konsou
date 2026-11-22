import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/hover_mark.dart';
import 'package:konsou/components/raised_key.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/shell/app_shell.dart';
import 'package:konsou/shell/maximize_button_link.dart';
import 'package:konsou/shell/window_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../support/render_png.dart' show loadAppFonts;

// the search well is the one live edge whose child is a Container; the window
// buttons' raised keys carry one too
final searchMark = find.byWidgetPredicate(
  (widget) => widget is HoverMark && widget.child is Container,
);

void main() {
  // An aligned Container once filled the whole bar, so its fill hid the
  // wordmark, the bell, the heart and the window buttons.
  for (final width in [900.0, 1100.0, 1600.0]) {
    testWidgets('the search well keeps its own size at a window $width wide', (
      tester,
    ) async {
      await loadAppFonts();
      tester.view.physicalSize = Size(width, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 300)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AppShell(child: Container()),
          ),
        ),
      );
      await tester.pump();
      final well = find
          .descendant(of: searchMark, matching: find.byType(Container))
          .first;
      final size = tester.getSize(well);
      expect(size.width, Tokens.quickSearchWidth);
      expect(size.height, Tokens.quickSearchHeight);
      // centred in the window
      expect(tester.getCenter(well).dx, closeTo(width / 2, 1));
    });
  }

  // Alt F4, the taskbar and the window menu reach the shell as a close
  // event; they once skipped the last sync, which only the button ran.
  for (final way in ['the close button', 'a close from Windows']) {
    testWidgets('$way hides the window, runs the last step, then quits', (
      tester,
    ) async {
      await loadAppFonts();
      SharedPreferences.setMockInitialValues({});
      final steps = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          if (call.method == 'hide' || call.method == 'destroy') {
            steps.add(call.method);
          }
          return call.method == 'getBounds'
              ? {'x': 0.0, 'y': 0.0, 'width': 1100.0, 'height': 700.0}
              : null;
        },
      );
      tester.view.physicalSize = const Size(1100, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1100, 300)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AppShell(
              beforeClose: () async => steps.add('last step'),
              child: Container(),
            ),
          ),
        ),
      );
      await tester.pump();
      if (way == 'the close button') {
        await tester.tap(find.bySemanticsLabel('Close'));
        // a second click while it shuts down does nothing
        await tester.tap(find.bySemanticsLabel('Close'));
      } else {
        for (final listener in windowManager.listeners) {
          listener.onWindowClose();
        }
      }
      await tester.pumpAndSettle();
      expect(steps, ['hide', 'last step', 'destroy']);
    });
  }

  // Windows owns the maximize button's pointer (for Snap Layouts) and says
  // what it is doing; the button has to draw it.
  testWidgets('the maximize button lights when Windows says it is hovered', (
    tester,
  ) async {
    await loadAppFonts();
    tester.view.physicalSize = const Size(1100, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1100, 300)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppShell(child: Container()),
        ),
      ),
    );
    await tester.pump();
    RaisedKey key() => tester.widget<RaisedKey>(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is WindowButton && widget.glyph == WindowGlyph.maximize,
        ),
        matching: find.byType(RaisedKey),
      ),
    );
    Future<void> say(MaximizeButtonState state) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        maximizeButtonChannel.name,
        maximizeButtonChannel.codec.encodeMethodCall(
          MethodCall('maximizeButtonState', state.index),
        ),
        (_) {},
      );
      await tester.pump();
    }

    expect(key().lit, isFalse);
    await say(MaximizeButtonState.hovered);
    expect(key().lit, isTrue);
    await say(MaximizeButtonState.pressed);
    expect(key().sunk, isTrue);
    await say(MaximizeButtonState.none);
    expect(key().lit, isFalse);
    expect(key().sunk, isFalse);
  });

  testWidgets('hovering the search well lights the live edge', (tester) async {
    await loadAppFonts();
    tester.view.physicalSize = const Size(1100, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1100, 300)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppShell(child: Container()),
        ),
      ),
    );
    await tester.pump();
    final mark = searchMark;
    expect(tester.widget<HoverMark>(mark).on, isFalse);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(5, 250));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(mark));
    await tester.pump();
    expect(tester.widget<HoverMark>(mark).on, isTrue);
    await mouse.moveTo(const Offset(5, 250));
    await tester.pump();
    expect(tester.widget<HoverMark>(mark).on, isFalse);
  });
}
