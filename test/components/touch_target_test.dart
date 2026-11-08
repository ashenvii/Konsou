import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_button.dart';
import 'package:konsou/components/app_checkbox.dart';
import 'package:konsou/components/touch_target.dart';
import 'package:konsou/design/tokens.dart';

import '../support/pump_widget.dart';

void main() {
  tearDown(() => TouchTarget.debugForce = null);

  testWidgets('on desktop nothing changes size', (tester) async {
    TouchTarget.debugForce = false;
    await pumpWidget(
      tester,
      AppCheckbox(value: CheckValue.empty, onChanged: (_) {}),
    );
    expect(
      tester.getSize(find.byType(AppCheckbox)),
      const Size.square(Tokens.checkboxSize),
    );
  });

  testWidgets('on touch a checkbox is hit over at least 48 by 48', (
    tester,
  ) async {
    TouchTarget.debugForce = true;
    var changes = 0;
    await pumpWidget(
      tester,
      AppCheckbox(value: CheckValue.empty, onChanged: (_) => changes++),
    );
    expect(
      tester.getSize(find.byType(AppCheckbox)),
      const Size.square(Tokens.touchTarget),
    );
    // 3 px in from the corner of the target, outside the 20 px box itself.
    await tester.tapAt(
      tester.getTopLeft(find.byType(AppCheckbox)) + const Offset(3, 3),
    );
    expect(changes, 1);
  });

  testWidgets('on touch a button is 48 tall and keeps its look at 36', (
    tester,
  ) async {
    TouchTarget.debugForce = true;
    await pumpWidget(tester, AppButton(label: 'Go', onPressed: () {}));
    expect(tester.getSize(find.byType(AppButton)).height, Tokens.touchTarget);
    final fill = find.descendant(
      of: find.byType(AppButton),
      matching: find.byType(Container),
    );
    expect(tester.getSize(fill.first).height, Tokens.controlHeight);
  });
}
