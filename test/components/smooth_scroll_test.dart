import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/smooth_scroll.dart';

void main() {
  late SmoothScrollController controller;

  Future<void> pumpList(WidgetTester tester, {bool still = false}) async {
    controller = SmoothScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: still),
          child: ListView.builder(
            controller: controller,
            itemExtent: 50,
            itemCount: 200,
            itemBuilder: (context, index) => Text('$index'),
          ),
        ),
      ),
    );
  }

  Future<void> wheel(WidgetTester tester, double dy) async {
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(const Offset(100, 100)));
    await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
  }

  testWidgets('a wheel notch glides there instead of jumping', (tester) async {
    await pumpList(tester);
    await wheel(tester, 200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.offset, inInclusiveRange(1, 199));
    await tester.pumpAndSettle();
    expect(controller.offset, 200 * wheelBoost);
  });

  testWidgets('notches during a glide add up', (tester) async {
    await pumpList(tester);
    await wheel(tester, 200);
    await tester.pump(const Duration(milliseconds: 50));
    await wheel(tester, 200);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(controller.offset, 400 * wheelBoost);
  });

  testWidgets('a notch mid-glide keeps the speed instead of restarting', (
    tester,
  ) async {
    await pumpList(tester);
    await wheel(tester, 200);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final before = controller.offset;
    await wheel(tester, 200);
    await tester.pump(const Duration(milliseconds: 16));
    // still moving forward, never pulled back or stopped by the new notch
    expect(controller.offset, greaterThan(before));
    await tester.pumpAndSettle();
    expect(controller.offset, 400 * wheelBoost);
  });

  testWidgets('a drag stops the glide', (tester) async {
    await pumpList(tester);
    await wheel(tester, 400);
    await tester.pump(const Duration(milliseconds: 16));
    controller.jumpTo(100);
    await tester.pumpAndSettle();
    expect(controller.offset, 100);
  });

  testWidgets('a click during the glide stops it and is not a click on a row', (
    tester,
  ) async {
    var tapped = 0;
    controller = SmoothScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          controller: controller,
          itemExtent: 50,
          itemCount: 200,
          itemBuilder: (context, index) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => tapped++,
            child: Text('$index'),
          ),
        ),
      ),
    );
    await wheel(tester, 400);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tapAt(const Offset(100, 100));
    await tester.pump();
    final stopped = controller.offset;
    await tester.pumpAndSettle();
    expect(tapped, 0);
    expect(controller.offset, stopped);
    await tester.tapAt(const Offset(100, 100));
    expect(tapped, 1);
  });

  testWidgets('it jumps when the system turns animations off', (tester) async {
    await pumpList(tester, still: true);
    await wheel(tester, 200);
    await tester.pump();
    expect(controller.offset, 200);
  });
}
