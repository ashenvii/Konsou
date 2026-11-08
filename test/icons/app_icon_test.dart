import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/icons/app_icons.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('is as wide as asked and as tall as its grid', (tester) async {
    await pumpWidget(
      tester,
      const AppIcon(AppIcons.nekomimi, size: 20, color: Tokens.mint),
    );
    // The face grid is 20 by 21, so at 20 wide it is 21 tall.
    expect(tester.getSize(find.byType(AppIcon)), const Size(20, 21));
    await pumpWidget(
      tester,
      const AppIcon(AppIcons.discover, size: 32, color: Tokens.mint),
    );
    expect(tester.getSize(find.byType(AppIcon)), const Size.square(32));
  });

  testWidgets('paints without errors with one or two colors', (tester) async {
    await pumpWidget(
      tester,
      const Column(
        children: [
          AppIcon(AppIcons.discover, size: 36, color: Tokens.ground),
          AppIcon(
            AppIcons.nekomimi,
            size: 80,
            color: Tokens.mint,
            lineColor: Tokens.ground,
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
