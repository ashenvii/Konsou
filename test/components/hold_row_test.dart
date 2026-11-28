import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/hold_row.dart';
import 'package:konsou/components/shake.dart';
import 'package:konsou/design/tokens.dart';

void main() {
  late int done;

  Future<void> pumpRow(WidgetTester tester) async {
    done = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: HoldRow(
            label: holdToRemoveLabel,
            holdTime: const Duration(seconds: 1),
            onDone: () => done++,
          ),
        ),
      ),
    );
  }

  Future<void> hold(WidgetTester tester, int buttons) async {
    final pointer = await tester.startGesture(
      tester.getCenter(find.byType(HoldRow)),
      kind: PointerDeviceKind.mouse,
      buttons: buttons,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await pointer.up();
  }

  testWidgets('a held left click runs it', (tester) async {
    await pumpRow(tester);
    await hold(tester, kPrimaryMouseButton);
    expect(done, 1);
  });

  testWidgets('letting go early shakes the key and runs nothing', (
    tester,
  ) async {
    await pumpRow(tester);
    final pointer = await tester.startGesture(
      tester.getCenter(find.byType(HoldRow)),
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await pointer.up();
    await tester.pump();
    await tester.pump(Tokens.motionQuick ~/ 3);
    final moved = tester.widget<Transform>(
      find
          .descendant(of: find.byType(Shake), matching: find.byType(Transform))
          .first,
    );
    expect(moved.transform.getTranslation().x, isNot(0));
    await tester.pumpAndSettle();
    expect(done, 0);
  });

  testWidgets('a right or middle click starts no hold', (tester) async {
    await pumpRow(tester);
    await hold(tester, kSecondaryMouseButton);
    await hold(tester, kMiddleMouseButton);
    expect(done, 0);
  });
}
