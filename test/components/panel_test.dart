import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/panel.dart';
import 'package:konsou/design/tokens.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('wraps its child in the surface fill with 16 padding', (
    tester,
  ) async {
    await pumpWidget(
      tester,
      const Panel(child: SizedBox(width: 50, height: 20)),
    );
    expect(fillOf(tester, find.byType(Panel)), Tokens.surface);
    final size = tester.getSize(find.byType(Panel));
    expect(size.width, 50 + 2 * Tokens.space4);
    expect(size.height, 20 + 2 * Tokens.space4);
  });

  testWidgets('padding can be changed', (tester) async {
    await pumpWidget(
      tester,
      const Panel(
        padding: Tokens.space2,
        child: SizedBox(width: 10, height: 10),
      ),
    );
    expect(tester.getSize(find.byType(Panel)).width, 10 + 2 * Tokens.space2);
  });
}
