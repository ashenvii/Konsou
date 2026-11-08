import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_tab.dart';
import 'package:konsou/components/count_badge.dart';
import 'package:konsou/design/tokens.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('selected is amber, the others have no fill', (tester) async {
    await pumpWidget(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTab(label: 'Browse', selected: true, onPressed: () {}),
          AppTab(label: 'Top 10', selected: false, onPressed: () {}),
        ],
      ),
    );
    expect(fillOf(tester, find.widgetWithText(AppTab, 'Browse')), Tokens.amber);
    expect(fillOf(tester, find.widgetWithText(AppTab, 'Top 10')), isNull);
  });

  testWidgets('a tap fires and a count shows a badge', (tester) async {
    var taps = 0;
    await pumpWidget(
      tester,
      AppTab(
        label: 'Watching',
        selected: false,
        count: 5,
        onPressed: () => taps++,
      ),
    );
    expect(find.byType(CountBadge), findsOneWidget);
    await tester.tap(find.byType(AppTab));
    expect(taps, 1);
  });

  testWidgets('the selected label is bold, the others are regular', (
    tester,
  ) async {
    await pumpWidget(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTab(label: 'Browse', selected: true, onPressed: () {}),
          AppTab(label: 'Top 10', selected: false, onPressed: () {}),
        ],
      ),
    );
    FontWeight? weight(String label) =>
        tester.widget<Text>(find.text(label)).style?.fontWeight;
    expect(weight('Browse'), FontWeight.w700);
    expect(weight('Top 10'), FontWeight.w400);
  });

  testWidgets('selecting a tab does not change its width', (tester) async {
    Future<double> widthWhen(bool selected) async {
      await pumpWidget(
        tester,
        AppTab(label: 'For you', selected: selected, onPressed: () {}),
      );
      return tester.getSize(find.byType(AppTab)).width;
    }

    expect(await widthWhen(true), await widthWhen(false));
  });

  testWidgets('a badge on the selected tab turns dark', (tester) async {
    await pumpWidget(
      tester,
      AppTab(label: 'Watching', selected: true, count: 5, onPressed: () {}),
    );
    expect(fillOf(tester, find.byType(CountBadge)), Tokens.ground);
    await pumpWidget(
      tester,
      AppTab(label: 'Watching', selected: false, count: 5, onPressed: () {}),
    );
    expect(fillOf(tester, find.byType(CountBadge)), Tokens.mint);
  });

  testWidgets('tab width is the label plus 16 each side', (tester) async {
    await pumpWidget(
      tester,
      AppTab(label: 'For you', selected: false, onPressed: () {}),
    );
    final text = tester.getSize(find.text('For you')).width;
    expect(tester.getSize(find.byType(AppTab)).width, text + 2 * Tokens.space4);
  });
}
