import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_scroll_behavior.dart';
import 'package:konsou/design/tokens.dart';

void main() {
  Future<void> pumpList(WidgetTester tester) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(400, 300)),
        child: ScrollConfiguration(
          behavior: const AppScrollBehavior(),
          child: ListView(
            children: [
              for (var i = 0; i < 50; i++)
                SizedBox(height: 40, child: Text('$i')),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets('a desktop list has exactly one scrollbar, the mint one', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpList(tester);
      final bars = tester.widgetList<RawScrollbar>(find.byType(RawScrollbar));
      expect(bars, hasLength(1));
      expect(bars.single.thumbColor, Tokens.mint);
      expect(bars.single.thumbVisibility, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a phone list has no scrollbar', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await pumpList(tester);
      expect(find.byType(RawScrollbar), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
