import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/hover_mark.dart';
import 'package:konsou/components/sweep_button.dart';

Widget _app({required VoidCallback onPressed, bool still = false}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: still),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SweepButton(label: 'Screenshot', onPressed: onPressed),
        ),
      ),
    );

void main() {
  testWidgets('is only its text at rest, and the live edge shows on hover', (
    tester,
  ) async {
    await tester.pumpWidget(_app(onPressed: () {}));
    expect(find.text('Screenshot'), findsOneWidget);
    expect(tester.widget<HoverMark>(find.byType(HoverMark)).on, isFalse);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(SweepButton)));
    await tester.pump();
    expect(tester.widget<HoverMark>(find.byType(HoverMark)).on, isTrue);
  });

  testWidgets('a tap presses it', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(_app(onPressed: () => pressed++));
    await tester.tap(find.byType(SweepButton));
    expect(pressed, 1);
  });

  testWidgets('sweeps once soon after it shows, then rests', (tester) async {
    await tester.pumpWidget(_app(onPressed: () {}));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(
      SweepButton.firstSweep + const Duration(milliseconds: 50),
    );
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(SweepButton.sweepTime);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('does not sweep under reduced motion', (tester) async {
    await tester.pumpWidget(_app(onPressed: () {}, still: true));
    await tester.pump(
      SweepButton.firstSweep + const Duration(milliseconds: 50),
    );
    expect(tester.hasRunningAnimations, isFalse);
  });
}
