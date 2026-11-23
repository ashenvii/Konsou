import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/icon_square_button.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/icons/app_icons.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('is a control-height square with its icon', (tester) async {
    await pumpWidget(
      tester,
      IconSquareButton(icon: AppIcons.more, label: 'More', onPressed: () {}),
    );
    expect(
      tester.getSize(find.byType(IconSquareButton)),
      const Size.square(Tokens.controlHeight),
    );
    expect(tester.widget<AppIcon>(find.byType(AppIcon)).def, AppIcons.more);
  });

  testWidgets('a tap runs it', (tester) async {
    var taps = 0;
    await pumpWidget(
      tester,
      IconSquareButton(
        icon: AppIcons.more,
        label: 'More',
        onPressed: () => taps++,
      ),
    );
    await tester.tap(find.byType(IconSquareButton));
    expect(taps, 1);
  });
}
