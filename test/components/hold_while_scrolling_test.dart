import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/hold_while_scrolling.dart';

void main() {
  final value = ValueNotifier('old');
  setUp(() => value.value = 'old');

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder(
          valueListenable: value,
          builder: (context, text, _) => HoldWhileScrolling(
            value: text,
            builder: (context, shown) => ListView.builder(
              itemExtent: 50,
              itemCount: 100,
              itemBuilder: (context, index) => Text(index == 0 ? shown : ''),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a change at rest shows at once', (tester) async {
    await pumpList(tester);
    value.value = 'new';
    await tester.pump();
    expect(find.text('new'), findsOneWidget);
  });

  testWidgets('a change mid-scroll waits for the scroll to end', (
    tester,
  ) async {
    await pumpList(tester);
    final drag = await tester.startGesture(const Offset(100, 300));
    await drag.moveBy(const Offset(0, -20));
    await tester.pump();
    value.value = 'new';
    await tester.pump();
    expect(find.text('old'), findsOneWidget);
    await drag.moveBy(const Offset(0, 20));
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.text('new'), findsOneWidget);
  });

  testWidgets('a scroll inside the list does not hold it', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder(
          valueListenable: value,
          builder: (context, text, _) => HoldWhileScrolling(
            value: text,
            builder: (context, shown) => ListView(
              children: [
                Text(shown),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    key: const Key('rail'),
                    scrollDirection: Axis.horizontal,
                    itemExtent: 100,
                    itemCount: 50,
                    itemBuilder: (context, index) => const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final drag = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('rail'))),
    );
    await drag.moveBy(const Offset(-40, 0));
    await tester.pump();
    value.value = 'new';
    await tester.pump();
    expect(find.text('new'), findsOneWidget);
    await drag.up();
    await tester.pumpAndSettle();
  });
}
