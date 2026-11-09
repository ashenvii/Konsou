import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/shell/app_rail.dart';

import '../support/pump_widget.dart';

void main() {
  Future<List<String>> pumpRail(WidgetTester tester, String location) async {
    final picked = <String>[];
    await pumpWidget(
      tester,
      SizedBox(
        width: Tokens.railWidth,
        height: 400,
        child: AppRail(location: location, onSelect: picked.add),
      ),
    );
    return picked;
  }

  testWidgets('shows the five places, Settings last', (tester) async {
    await pumpRail(tester, libraryPath);
    for (final label in [
      'Library',
      'Watching',
      'Discover',
      'Schedule',
      'Settings',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    final library = tester.getTopLeft(find.bySemanticsLabel('Library')).dy;
    final settings = tester.getTopLeft(find.bySemanticsLabel('Settings')).dy;
    expect(settings, greaterThan(library));
  });

  testWidgets('only the page showing is amber, on a 36 square', (tester) async {
    await pumpRail(tester, discoverPath);
    final active = find.bySemanticsLabel('Discover');
    expect(fillOf(tester, active), Tokens.amber);
    expect(
      tester.getSize(
        find.descendant(of: active, matching: find.byType(ColoredBox)).first,
      ),
      const Size.square(Tokens.railItemSize),
    );
    for (final label in ['Library', 'Watching', 'Schedule', 'Settings']) {
      expect(fillOf(tester, find.bySemanticsLabel(label)), isNot(Tokens.amber));
    }
  });

  testWidgets('Library is active only on its own path', (tester) async {
    await pumpRail(tester, watchingPath);
    expect(
      fillOf(tester, find.bySemanticsLabel('Library')),
      isNot(Tokens.amber),
    );
    expect(fillOf(tester, find.bySemanticsLabel('Watching')), Tokens.amber);
  });

  testWidgets('a tap names the place', (tester) async {
    final picked = await pumpRail(tester, libraryPath);
    await tester.tap(find.bySemanticsLabel('Schedule'));
    await tester.tap(find.bySemanticsLabel('Settings'));
    expect(picked, [schedulePath, settingsPath]);
  });
}
