import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/pressable.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('a tap calls onPressed', (tester) async {
    var taps = 0;
    await pumpWidget(
      tester,
      Pressable(
        onPressed: () => taps++,
        builder: (_, _) => const SizedBox(width: 40, height: 40),
      ),
    );
    await tester.tap(find.byType(Pressable));
    expect(taps, 1);
  });

  testWidgets('enter and space activate it when focused', (tester) async {
    var taps = 0;
    await pumpWidget(
      tester,
      Pressable(
        autofocus: true,
        onPressed: () => taps++,
        builder: (_, _) => const SizedBox(width: 40, height: 40),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 2);
  });

  testWidgets('disabled cannot take focus and reads as disabled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpWidget(
      tester,
      Pressable(
        autofocus: true,
        onPressed: null,
        builder: (_, _) => const SizedBox(width: 40, height: 40),
      ),
    );
    await tester.pump();
    final detector = tester.widget<FocusableActionDetector>(
      find.byType(FocusableActionDetector),
    );
    expect(detector.enabled, isFalse);
    final inside = tester.element(
      find
          .descendant(
            of: find.byType(Pressable),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(Focus.of(inside).hasFocus, isFalse);
    expect(
      tester.getSemantics(find.byType(Pressable)),
      matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('a disabled pressable does not report hover', (tester) async {
    var hovered = true;
    await pumpWidget(
      tester,
      Pressable(
        onPressed: null,
        builder: (_, state) {
          hovered = state.hovered;
          return const SizedBox(width: 40, height: 40);
        },
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(500, 500));
    await mouse.moveTo(const Offset(20, 20));
    await tester.pump();
    expect(hovered, isFalse);
  });

  testWidgets('hover reaches the builder', (tester) async {
    var hovered = false;
    await pumpWidget(
      tester,
      Pressable(
        onPressed: () {},
        builder: (_, state) {
          hovered = state.hovered;
          return const SizedBox(width: 40, height: 40);
        },
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(500, 500));
    await mouse.moveTo(const Offset(20, 20));
    await tester.pump();
    expect(hovered, isTrue);
    await mouse.moveTo(const Offset(500, 500));
    await tester.pump();
    expect(hovered, isFalse);
  });
}
