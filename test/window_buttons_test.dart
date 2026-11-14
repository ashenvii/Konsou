import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/design/tokens.dart';
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

  Color fillOf(WidgetTester tester) => tester
      .widget<ColoredBox>(
        find.descendant(
          of: find.byType(WindowButton),
          matching: find.byType(ColoredBox),
        ),
      )
      .color;

  testWidgets('close fills red under the pointer and dims while held', (
    tester,
  ) async {
    await pumpWidget(
      tester,
      WindowButton(glyph: WindowGlyph.close, onPressed: () {}),
    );
    expect(fillOf(tester).a, 0);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(WindowButton)));
    await tester.pump();
    expect(fillOf(tester), Tokens.red);
    await mouse.down(tester.getCenter(find.byType(WindowButton)));
    await tester.pump();
    expect(fillOf(tester).a, lessThan(1));
    await mouse.up();
    await tester.pump();
    expect(fillOf(tester), Tokens.red);
  });

  testWidgets('minimize gets a faint fill, never red', (tester) async {
    await pumpWidget(
      tester,
      WindowButton(glyph: WindowGlyph.minimize, onPressed: () {}),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(WindowButton)));
    await tester.pump();
    final fill = fillOf(tester);
    expect(fill.withValues(alpha: 1), Tokens.ink);
    expect(fill.a, greaterThan(0));
    expect(fill.a, lessThan(0.2));
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
