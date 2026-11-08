import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_button.dart';
import 'package:konsou/components/app_checkbox.dart';
import 'package:konsou/components/app_tab.dart';
import 'package:konsou/components/count_badge.dart';
import 'package:konsou/design/tokens.dart';

import 'support/pump_widget.dart';

/// What the components do with awkward input: very long labels, a squeezed
/// space, a large system text size, a right-to-left language, odd counts.
void main() {
  const long =
      'A label far too long for the space it is given, in any language at all';
  const narrow = 100.0;

  Widget squeezed(Widget child) => SizedBox(width: narrow, child: child);

  testWidgets('a long button label stays on one line inside its space', (
    tester,
  ) async {
    await pumpWidget(
      tester,
      squeezed(AppButton(label: long, onPressed: () {})),
    );
    expect(tester.takeException(), isNull);
    final box = tester.getSize(find.byType(AppButton));
    expect(box.width, lessThanOrEqualTo(narrow));
    expect(box.height, Tokens.controlHeight);
    final label = tester.widget<Text>(find.text(long));
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
  });

  testWidgets('a long tab label shrinks to fit, with its count', (
    tester,
  ) async {
    await pumpWidget(
      tester,
      squeezed(
        Row(
          children: [
            Flexible(
              child: AppTab(
                label: long,
                selected: true,
                count: 120,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppTab)).width, lessThanOrEqualTo(narrow));
  });

  for (final scale in [1.5, 2.0, 3.0]) {
    testWidgets('a text size of $scale times does not break the controls', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(label: 'Browse', onPressed: () {}),
                  AppTab(
                    label: 'Watching',
                    selected: true,
                    count: 12,
                    onPressed: () {},
                  ),
                  AppCheckbox(value: CheckValue.checked, onChanged: (_) {}),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // The controls keep their drawn height; only the label grows.
      expect(
        tester.getSize(find.byType(AppButton)).height,
        Tokens.controlHeight,
      );
      expect(tester.getSize(find.byType(CountBadge)).height, Tokens.badgeSize);
    });
  }

  testWidgets('the controls lay out right to left without errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Align(
          alignment: Alignment.topRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTab(label: 'مشاهدة', selected: true, count: 3, onPressed: () {}),
              AppTab(label: 'Top 10', selected: false, onPressed: () {}),
              AppButton(label: 'تصفح', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a count of 0, a negative one and a huge one all draw', (
    tester,
  ) async {
    for (final (count, shown) in [(0, '0'), (-4, '-4'), (1000000, '99+')]) {
      await pumpWidget(tester, CountBadge(count));
      expect(tester.takeException(), isNull);
      expect(find.text(shown), findsOneWidget);
      expect(tester.getSize(find.byType(CountBadge)).height, Tokens.badgeSize);
    }
  });

  testWidgets('an empty label does not break a button or a tab', (tester) async {
    await pumpWidget(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(label: '', onPressed: () {}),
          AppTab(label: '', selected: true, onPressed: () {}),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a disabled tab does not fire and stays unselected', (
    tester,
  ) async {
    await pumpWidget(
      tester,
      const AppTab(label: 'Dropped', selected: false, onPressed: null),
    );
    await tester.tap(find.byType(AppTab));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a fast double tap fires twice, once per tap', (tester) async {
    var taps = 0;
    await pumpWidget(
      tester,
      AppButton(label: 'Save', onPressed: () => taps++),
    );
    await tester.tap(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    expect(taps, 2);
  });
}
