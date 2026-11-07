import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/icons/app_icons.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('draws square at the size it is given', (tester) async {
    await pumpWidget(
      tester,
      const AppIcon(AppIcons.nekomimi, size: 20, color: Tokens.mint),
    );
    expect(tester.getSize(find.byType(AppIcon)), const Size.square(20));
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
