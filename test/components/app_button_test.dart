import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_button.dart';
import 'package:konsou/design/tokens.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('primary is amber, 36 tall, and fires on tap', (tester) async {
    var taps = 0;
    await pumpWidget(
      tester,
      AppButton(label: 'Browse', onPressed: () => taps++),
    );
    expect(fillOf(tester, find.byType(AppButton)), Tokens.amber);
    expect(tester.getSize(find.byType(AppButton)).height, Tokens.controlHeight);
    await tester.tap(find.byType(AppButton));
    expect(taps, 1);
  });

  testWidgets('secondary sits on the surface fill', (tester) async {
    await pumpWidget(
      tester,
      AppButton(
        label: 'Surprise me',
        kind: ButtonKind.secondary,
        onPressed: () {},
      ),
    );
    expect(fillOf(tester, find.byType(AppButton)), Tokens.surface);
  });

  testWidgets('width is the label plus 16 each side', (tester) async {
    await pumpWidget(tester, AppButton(label: 'Go', onPressed: () {}));
    final text = tester.getSize(find.text('Go')).width;
    final button = tester.getSize(find.byType(AppButton)).width;
    expect(button, text + 2 * Tokens.space4);
  });

  testWidgets('disabled primary drops the amber', (tester) async {
    await pumpWidget(tester, const AppButton(label: 'Save', onPressed: null));
    expect(fillOf(tester, find.byType(AppButton)), Tokens.surface);
  });
}
