import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/more_button.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/icons/app_icons.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('is a control-height square with the three dots', (tester) async {
    await pumpWidget(tester, MoreButton(onPressed: () {}));
    expect(
      tester.getSize(find.byType(MoreButton)),
      const Size.square(Tokens.controlHeight),
    );
    expect(tester.widget<AppIcon>(find.byType(AppIcon)).def, AppIcons.more);
  });

  testWidgets('a tap runs it', (tester) async {
    var taps = 0;
    await pumpWidget(tester, MoreButton(onPressed: () => taps++));
    await tester.tap(find.byType(MoreButton));
    expect(taps, 1);
  });
}
