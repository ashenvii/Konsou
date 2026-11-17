import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/presence.dart';

void main() {
  Widget host({
    required bool visible,
    bool slide = false,
    VoidCallback? gone,
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: Presence(
      visible: visible,
      slide: slide,
      onGone: gone,
      child: const SizedBox(key: Key('box'), width: 10, height: 10),
    ),
  );

  testWidgets('fades in over 120 ms and slides 4 px down into place', (
    tester,
  ) async {
    await tester.pumpWidget(host(visible: true, slide: true));
    final start = tester.getTopLeft(find.byKey(const Key('box'))).dy;
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.getTopLeft(find.byKey(const Key('box'))).dy, start + 4);
  });

  testWidgets('goes out in 80 ms with no slide, then is gone', (tester) async {
    var gone = 0;
    await tester.pumpWidget(
      host(visible: true, slide: true, gone: () => gone++),
    );
    await tester.pumpAndSettle();
    final rest = tester.getTopLeft(find.byKey(const Key('box'))).dy;
    await tester.pumpWidget(
      host(visible: false, slide: true, gone: () => gone++),
    );
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(const Key('box')), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const Key('box'))).dy, rest);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('box')), findsNothing);
    expect(gone, 1);
  });

  testWidgets('reduced motion is instant', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(visible: true, slide: true),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('box')), findsOneWidget);
  });
}
