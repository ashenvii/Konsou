import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/flap.dart';
import 'package:konsou/design/tokens.dart';

void main() {
  Widget flap(String face) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: Flap(face: face, plate: Tokens.surface, child: Text(face)),
    ),
  );

  testWidgets('both faces show while it turns, then only the new one', (
    tester,
  ) async {
    await tester.pumpWidget(flap('Konsou'));
    await tester.pumpWidget(flap('1,240'));
    await tester.pump(Tokens.motionFlap ~/ 2);
    expect(find.text('Konsou'), findsWidgets);
    expect(find.text('1,240'), findsWidgets);
    await tester.pump(Tokens.motionFlap);
    await tester.pump();
    expect(find.text('Konsou'), findsNothing);
    expect(find.text('1,240'), findsOneWidget);
  });

  testWidgets('with reduced motion the face changes in place', (tester) async {
    Widget still(String face) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: flap(face),
    );
    await tester.pumpWidget(still('Konsou'));
    await tester.pumpWidget(still('1,240'));
    expect(find.text('Konsou'), findsNothing);
    expect(find.text('1,240'), findsOneWidget);
  });
}
