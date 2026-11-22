import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/raised_key.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/icons/app_icons.dart';
import 'package:konsou/shell/window_buttons.dart';

import 'support/pump_widget.dart';

void main() {
  testWidgets('a tap calls onPressed and the button has its size', (
    tester,
  ) async {
    var taps = 0;
    await pumpWidget(
      tester,
      WindowButton(glyph: WindowGlyph.close, onPressed: () => taps++),
    );
    expect(
      tester.getSize(find.byType(WindowButton)),
      const Size(Tokens.windowButtonWidth, Tokens.barHeight),
    );
    await tester.tap(find.byType(WindowButton));
    expect(taps, 1);
  });

  testWidgets('it is a raised key holding a library icon at the app size', (
    tester,
  ) async {
    await pumpWidget(
      tester,
      WindowButton(glyph: WindowGlyph.maximize, onPressed: () {}),
    );
    expect(find.byType(RaisedKey), findsOneWidget);
    final icon = tester.widget<AppIcon>(find.byType(AppIcon));
    expect(icon.def, AppIcons.maximize);
    expect(icon.size, Tokens.iconSize);
  });

  Color iconColor(WidgetTester tester) =>
      tester.widget<AppIcon>(find.byType(AppIcon)).color;

  Future<TestGesture> hover(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(WindowButton)));
    await tester.pump();
    return mouse;
  }

  testWidgets('close turns red under the pointer and sinks while held', (
    tester,
  ) async {
    await pumpWidget(
      tester,
      WindowButton(glyph: WindowGlyph.close, onPressed: () {}),
    );
    expect(iconColor(tester), Tokens.inkMuted);
    final mouse = await hover(tester);
    expect(iconColor(tester), Tokens.red);
    expect(tester.widget<RaisedKey>(find.byType(RaisedKey)).sunk, isFalse);
    await mouse.down(tester.getCenter(find.byType(WindowButton)));
    await tester.pump();
    expect(tester.widget<RaisedKey>(find.byType(RaisedKey)).sunk, isTrue);
    await mouse.up();
  });

  testWidgets('minimize brightens to ink, never red', (tester) async {
    await pumpWidget(
      tester,
      WindowButton(glyph: WindowGlyph.minimize, onPressed: () {}),
    );
    await hover(tester);
    expect(iconColor(tester), Tokens.ink);
  });

  testWidgets('each glyph has a spoken name', (tester) async {
    final handle = tester.ensureSemantics();
    for (final (glyph, name) in [
      (WindowGlyph.minimize, 'Minimize'),
      (WindowGlyph.maximize, 'Maximize'),
      (WindowGlyph.restore, 'Restore'),
      (WindowGlyph.close, 'Close'),
    ]) {
      await pumpWidget(tester, WindowButton(glyph: glyph, onPressed: () {}));
      expect(find.bySemanticsLabel(name), findsOneWidget);
    }
    handle.dispose();
  });
}
