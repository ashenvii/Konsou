import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/hover_details.dart';
import 'package:konsou/components/hover_delays.dart';
import 'package:konsou/design/tokens.dart';

void main() {
  const anchorKey = Key('anchor');

  // the overlay keeps its first entry, so later changes come through this
  final focus = ValueNotifier(false);

  Future<void> pump(
    WidgetTester tester, {
    bool focused = false,
    bool enabled = true,
    bool still = false,
  }) {
    focus.value = focused;
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: still),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => Align(
                  alignment: Alignment.topLeft,
                  child: ValueListenableBuilder(
                    valueListenable: focus,
                    builder: (context, focused, _) => HoverDetails(
                      focused: focused,
                      enabled: enabled,
                      details: (_) => const Text('Details'),
                      child: const SizedBox(
                        key: anchorKey,
                        width: 168,
                        height: 300,
                        child: ColoredBox(color: Tokens.surface),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<TestGesture> mouseAt(WidgetTester tester, Offset at) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: at);
    addTearDown(mouse.removePointer);
    await tester.pump();
    return mouse;
  }

  testWidgets('opens beside the anchor after the tip delay', (tester) async {
    await pump(tester);
    await mouseAt(tester, tester.getCenter(find.byKey(anchorKey)));
    await tester.pump(Tokens.tipDelay - const Duration(milliseconds: 50));
    expect(find.text('Details'), findsNothing);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Details')).dx,
      greaterThan(tester.getTopRight(find.byKey(anchorKey)).dx),
    );
  });

  testWidgets('it is the popover width', (tester) async {
    await pump(tester, focused: true);
    await tester.pump(Tokens.tipDelay);
    await tester.pumpAndSettle();
    final panel = find.ancestor(
      of: find.text('Details'),
      matching: find.byType(SizedBox),
    );
    expect(tester.getSize(panel.first).width, Tokens.popoverWidth);
  });

  testWidgets('stays while the pointer crosses onto it, closes once both are '
      'left', (tester) async {
    await pump(tester);
    final mouse = await mouseAt(
      tester,
      tester.getCenter(find.byKey(anchorKey)),
    );
    await tester.pump(Tokens.tipDelay);
    await tester.pumpAndSettle();
    await mouse.moveTo(tester.getCenter(find.text('Details')));
    await tester.pump(HoverDelays.closeDelay * 2);
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);

    await mouse.moveTo(const Offset(790, 590));
    await tester.pump(HoverDelays.closeDelay * 2);
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
  });

  testWidgets('keyboard focus opens it too, and leaving closes it', (
    tester,
  ) async {
    await pump(tester, focused: true);
    await tester.pump(Tokens.tipDelay);
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    focus.value = false;
    await tester.pump(HoverDelays.closeDelay * 2);
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
  });

  testWidgets('a press on the anchor closes it', (tester) async {
    await pump(tester);
    final mouse = await mouseAt(
      tester,
      tester.getCenter(find.byKey(anchorKey)),
    );
    await tester.pump(Tokens.tipDelay);
    await tester.pumpAndSettle();
    await mouse.down(tester.getCenter(find.byKey(anchorKey)));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
  });

  testWidgets('turned off, it never opens', (tester) async {
    await pump(tester, focused: true, enabled: false);
    await tester.pump(Tokens.tipDelay * 2);
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
  });

  testWidgets('under reduced motion it shows whole at once, after the same '
      'wait', (tester) async {
    await pump(tester, focused: true, still: true);
    await tester.pump(Tokens.tipDelay - const Duration(milliseconds: 50));
    expect(find.text('Details'), findsNothing);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    final fade = tester.widget<FadeTransition>(
      find.ancestor(
        of: find.text('Details'),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, 1);
  });
}
