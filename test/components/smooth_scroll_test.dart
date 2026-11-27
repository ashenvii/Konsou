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

  testWidgets('a click during the glide is a click on the row', (tester) async {
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
    expect(controller.position.activity?.shouldIgnorePointer, isFalse);
    await tester.tapAt(const Offset(100, 100));
    await tester.pump();
    expect(tapped, 1);
    // pressing down holds the glide where it is, as it does any scroll
    final held = controller.offset;
    await tester.pumpAndSettle();
    expect(controller.offset, held);
  });

  testWidgets('a long spin is not cut short', (tester) async {
    await pumpList(tester);
    // one notch every 50 ms for 5 s, well past the safety limit
    for (var i = 0; i < 100; i++) {
      await wheel(tester, 20);
      await tester.pump(const Duration(milliseconds: 50));
    }
    final spinning = controller.offset;
    expect(spinning, lessThan(100 * 20 * wheelBoost));
    await tester.pumpAndSettle();
    expect(controller.offset, 100 * 20 * wheelBoost);
    expect(spinning, greaterThan(100 * 20 * wheelBoost * 0.8));
  });

  testWidgets('every glide lands and the list takes clicks after it', (
    tester,
  ) async {
    // the notches of a real wheel run, which once left the glide two pixels
    // short of its stop for good, ignoring every click
    for (final ratio in [1.0, 1.25, 1.5]) {
      var tapped = 0;
      controller = SmoothScrollController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(devicePixelRatio: ratio),
            child: ListView.builder(
              controller: controller,
              itemExtent: 50,
              itemCount: 400,
              itemBuilder: (context, index) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => tapped++,
                child: Text('$index'),
              ),
            ),
          ),
        ),
      );
      for (final dy in [60.0, 60.0, 120.0, -60.0, 60.0, 180.0]) {
        await wheel(tester, dy);
        for (var f = 0; f < 3; f++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      for (var f = 0; f < 200; f++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final position = controller.position;
      expect(
        position.activity?.shouldIgnorePointer,
        isFalse,
        reason: 'still gliding at $ratio, at ${position.pixels}',
      );
      expect(position.pixels, closeTo(420 * wheelBoost, 1 / ratio));
      expect((position.pixels * ratio) % 1, closeTo(0, 1e-6));
      await tester.tapAt(const Offset(100, 100));
      expect(tapped, 1, reason: 'a click after the glide at $ratio');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    }
  });

  testWidgets('it jumps when the system turns animations off', (tester) async {
    await pumpList(tester, still: true);
    await wheel(tester, 200);
    await tester.pump();
    expect(controller.offset, 200);
  });
}
