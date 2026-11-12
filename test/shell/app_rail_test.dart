import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
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

  Color iconOf(WidgetTester tester, String label) => tester
      .widget<AppIcon>(
        find.descendant(
          of: find.bySemanticsLabel(label),
          matching: find.byType(AppIcon),
        ),
      )
      .color;

  testWidgets('only the page showing is amber, with a mark on the edge', (
    tester,
  ) async {
    await pumpRail(tester, discoverPath);
    expect(iconOf(tester, 'Discover'), Tokens.amber);
    final mark = find.descendant(
      of: find.bySemanticsLabel('Discover'),
      matching: find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == Tokens.amber,
      ),
    );
    expect(tester.getSize(mark).width, Tokens.hoverEdge);
    for (final label in ['Library', 'Watching', 'Schedule', 'Settings']) {
      expect(iconOf(tester, label), Tokens.inkMuted);
    }
  });

  testWidgets('Library is active only on its own path', (tester) async {
    await pumpRail(tester, watchingPath);
    expect(iconOf(tester, 'Library'), Tokens.inkMuted);
    expect(iconOf(tester, 'Watching'), Tokens.amber);
  });

  testWidgets('a tap names the place', (tester) async {
    final picked = await pumpRail(tester, libraryPath);
    await tester.tap(find.bySemanticsLabel('Schedule'));
    await tester.tap(find.bySemanticsLabel('Settings'));
    expect(picked, [schedulePath, settingsPath]);
  });
}
