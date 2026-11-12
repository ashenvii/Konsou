import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_button.dart';
import 'package:konsou/components/app_tab.dart';
import 'package:konsou/components/icon_square_button.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/icons/app_icons.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('a button that opens a menu ends in a chevron', (tester) async {
    await pumpWidget(
      tester,
      AppButton(
        label: 'Recent',
        kind: ButtonKind.secondary,
        opensMenu: true,
        onPressed: () {},
      ),
    );
    final icon = tester.widget<AppIcon>(find.byType(AppIcon));
    expect(icon.def, AppIcons.chevronDown);
    expect(tester.getSize(find.byType(AppButton)).height, Tokens.controlHeight);
  });

  testWidgets('a plain button has no chevron', (tester) async {
    await pumpWidget(tester, AppButton(label: 'Open', onPressed: () {}));
    expect(find.byType(AppIcon), findsNothing);
  });

  testWidgets('a tab that opens a menu ends in a chevron', (tester) async {
    await pumpWidget(
      tester,
      AppTab(label: 'More', selected: false, opensMenu: true, onPressed: () {}),
    );
    expect(
      tester.widget<AppIcon>(find.byType(AppIcon)).def,
      AppIcons.chevronDown,
    );
  });

  group('icon square button', () {
    testWidgets('is a control-height square', (tester) async {
      await pumpWidget(
        tester,
        IconSquareButton(
          icon: AppIcons.grid,
          label: 'Grid view',
          onPressed: () {},
        ),
      );
      expect(
        tester.getSize(find.byType(IconSquareButton)),
        const Size.square(Tokens.controlHeight),
      );
    });

    testWidgets('selected is an amber icon with no box', (tester) async {
      await pumpWidget(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconSquareButton(
              icon: AppIcons.grid,
              label: 'Grid view',
              selected: true,
              onPressed: () {},
            ),
            IconSquareButton(
              icon: AppIcons.list,
              label: 'List view',
              onPressed: () {},
            ),
          ],
        ),
      );
      Color iconOf(String label) => tester
          .widget<AppIcon>(
            find.descendant(
              of: find.bySemanticsLabel(label),
              matching: find.byType(AppIcon),
            ),
          )
          .color;
      // no boxes: the chosen one is an amber icon, the other muted
      expect(iconOf('Grid view'), Tokens.amber);
      expect(iconOf('List view'), Tokens.inkMuted);
      expect(fillOf(tester, find.bySemanticsLabel('List view')), isNull);
    });

    testWidgets('a tap runs it', (tester) async {
      var taps = 0;
      await pumpWidget(
        tester,
        IconSquareButton(
          icon: AppIcons.list,
          label: 'List view',
          onPressed: () => taps++,
        ),
      );
      await tester.tap(find.byType(IconSquareButton));
      expect(taps, 1);
    });
  });
}
