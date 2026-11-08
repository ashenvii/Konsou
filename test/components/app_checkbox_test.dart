import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_checkbox.dart';
import 'package:konsou/design/tokens.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('is a 20 by 20 box', (tester) async {
    await pumpWidget(
      tester,
      AppCheckbox(value: CheckValue.empty, onChanged: (_) {}),
    );
    final size = tester.getSize(find.byType(AppCheckbox));
    expect(size.width, Tokens.checkboxSize);
    expect(size.height, Tokens.checkboxSize);
  });

  testWidgets('without exclude it flips empty and checked', (tester) async {
    CheckValue? got;
    await pumpWidget(
      tester,
      AppCheckbox(value: CheckValue.empty, onChanged: (v) => got = v),
    );
    await tester.tap(find.byType(AppCheckbox));
    expect(got, CheckValue.checked);

    await pumpWidget(
      tester,
      AppCheckbox(value: CheckValue.checked, onChanged: (v) => got = v),
    );
    await tester.tap(find.byType(AppCheckbox));
    expect(got, CheckValue.empty);
  });

  testWidgets('with exclude it goes empty, checked, excluded, empty', (
    tester,
  ) async {
    final seen = <CheckValue>[];
    for (final from in [
      CheckValue.empty,
      CheckValue.checked,
      CheckValue.excluded,
    ]) {
      await pumpWidget(
        tester,
        AppCheckbox(value: from, allowExclude: true, onChanged: seen.add),
      );
      await tester.tap(find.byType(AppCheckbox));
    }
    expect(seen, [CheckValue.checked, CheckValue.excluded, CheckValue.empty]);
  });

  testWidgets('excluded is spoken as excluded', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpWidget(
      tester,
      AppCheckbox(
        value: CheckValue.excluded,
        allowExclude: true,
        onChanged: (_) {},
      ),
    );
    expect(find.bySemanticsLabel('excluded'), findsNothing);
    expect(tester.getSemantics(find.byType(AppCheckbox)).value, 'excluded');
    handle.dispose();
  });

  testWidgets('disabled ignores taps', (tester) async {
    await pumpWidget(
      tester,
      const AppCheckbox(value: CheckValue.empty, onChanged: null),
    );
    await tester.tap(find.byType(AppCheckbox));
    expect(find.byType(AppCheckbox), findsOneWidget);
  });
}
