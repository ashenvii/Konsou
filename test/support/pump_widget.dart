import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Puts a widget in the smallest tree the components need.
Future<void> pumpWidget(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

/// The fill color of the first ColoredBox or Container color under [of].
Color? fillOf(WidgetTester tester, Finder of) {
  final box = find.descendant(of: of, matching: find.byType(ColoredBox));
  if (box.evaluate().isNotEmpty) {
    return tester.widget<ColoredBox>(box.first).color;
  }
  final container = find.descendant(of: of, matching: find.byType(Container));
  if (container.evaluate().isNotEmpty) {
    return tester.widget<Container>(container.first).color;
  }
  return null;
}
