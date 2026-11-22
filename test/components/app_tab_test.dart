import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_tab.dart';
import 'package:konsou/components/weight_text.dart';
import 'package:konsou/design/tokens.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('selected has a pop underline, the others nothing', (
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
    Decoration? lineOf(String label) => tester
        .widget<Container>(
          find.descendant(
            of: find.widgetWithText(AppTab, label),
            matching: find.byType(Container),
          ),
        )
        .foregroundDecoration;
    final line = lineOf('Browse')! as BoxDecoration;
    expect((line.border! as Border).bottom.color, Tokens.pop);
    expect(lineOf('Top 10'), isNull);
    expect(fillOf(tester, find.widgetWithText(AppTab, 'Browse')), isNull);
  });

  testWidgets('a tap fires and a count shows beside the word', (tester) async {
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
    expect(find.text('5'), findsOneWidget);
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
    expect(weight('Browse'), FontWeight.w600);
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

  testWidgets('the selected count lights up in pop', (tester) async {
    Color? countColor() => tester.widget<Text>(find.text('5')).style?.color;
    await pumpWidget(
      tester,
      AppTab(label: 'Watching', selected: true, count: 5, onPressed: () {}),
    );
    expect(countColor(), Tokens.pop);
    await pumpWidget(
      tester,
      AppTab(label: 'Watching', selected: false, count: 5, onPressed: () {}),
    );
    expect(countColor(), Tokens.inkMuted);
  });

  testWidgets('tab width is the label plus 16 each side', (tester) async {
    await pumpWidget(
      tester,
      AppTab(label: 'For you', selected: false, onPressed: () {}),
    );
    final label = tester.getSize(find.byType(WeightText)).width;
    expect(
      tester.getSize(find.byType(AppTab)).width,
      label + 2 * Tokens.space4,
    );
  });
}
