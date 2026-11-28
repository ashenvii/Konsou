import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/hold_row.dart';

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

  testWidgets('a right or middle click starts no hold', (tester) async {
    await pumpRow(tester);
    await hold(tester, kSecondaryMouseButton);
    await hold(tester, kMiddleMouseButton);
    expect(done, 0);
  });
}
