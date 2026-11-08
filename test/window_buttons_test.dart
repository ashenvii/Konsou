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
