import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/presence.dart';

void main() {
  Widget host({required bool visible, VoidCallback? gone}) => Directionality(
    textDirection: TextDirection.ltr,
    child: Presence(
      visible: visible,
      onGone: gone,
      child: const SizedBox(key: Key('box'), width: 10, height: 10),
    ),
  );

  double opacity(WidgetTester tester) =>
      tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value;

  testWidgets('fades in over 120 ms', (tester) async {
    await tester.pumpWidget(host(visible: true));
    expect(opacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 60));
    expect(opacity(tester), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 61));
    expect(opacity(tester), 1);
  });

  testWidgets('goes out in 80 ms, then is gone', (tester) async {
    var gone = 0;
    await tester.pumpWidget(host(visible: true, gone: () => gone++));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(visible: false, gone: () => gone++));
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(const Key('box')), findsOneWidget);
    expect(opacity(tester), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('box')), findsNothing);
    expect(gone, 1);
  });

  testWidgets('reduced motion is instant', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(visible: true),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('box')), findsOneWidget);
  });
}
