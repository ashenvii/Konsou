import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_button.dart';
import 'package:konsou/components/app_menu.dart';
import 'package:konsou/components/app_popover.dart';
import 'package:konsou/components/popover_placement.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/icons/app_icons.dart';

void main() {
  group('placement', () {
    const area = Size(800, 600);
    const child = Size(200, 100);

    test('under the anchor, lined up on the left', () {
      expect(
        placePopover(
          anchor: const Rect.fromLTWH(50, 40, 80, 36),
          child: child,
          area: area,
        ),
        const Offset(50, 76),
      );
    });

    test('pulled back in from the right edge', () {
      expect(
        placePopover(
          anchor: const Rect.fromLTWH(700, 40, 80, 36),
          child: child,
          area: area,
        ),
        const Offset(600, 76),
      );
    });

    test('flipped above when there is no room below', () {
      expect(
        placePopover(
          anchor: const Rect.fromLTWH(50, 540, 80, 36),
          child: child,
          area: area,
        ),
        const Offset(50, 440),
      );
    });

    test('never negative, even from a wide anchor or a small area', () {
      expect(
        placePopover(
          anchor: const Rect.fromLTWH(-300, 10, 2000, 36),
          child: child,
          area: area,
        ).dx,
        0,
      );
      final offset = placePopover(
        anchor: const Rect.fromLTWH(10, 40, 80, 36),
        child: const Size(300, 500),
        area: const Size(250, 300),
      );
      expect(offset.dx, greaterThanOrEqualTo(0));
      expect(offset.dy, greaterThanOrEqualTo(0));
    });

    test('a pointer position opens at the pointer', () {
      expect(
        placePopover(
          anchor: const Rect.fromLTWH(300, 200, 0, 0),
          child: child,
          area: area,
        ),
        const Offset(300, 200),
      );
    });
  });

  group('menu', () {
    Future<void> pumpMenu(WidgetTester tester, List<MenuEntry> entries) =>
        tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: AppMenu(entries: entries),
            ),
          ),
        );

    testWidgets('each row is control height and runs its action', (
      tester,
    ) async {
      final taken = <String>[];
      await pumpMenu(tester, [
        MenuEntry(
          label: 'Watching',
          shortcut: '1',
          onPressed: () => taken.add('w'),
        ),
        MenuEntry(
          label: 'Planned',
          shortcut: '2',
          onPressed: () => taken.add('p'),
        ),
      ]);
      expect(
        tester.getSize(find.text('Watching')).height,
        lessThan(Tokens.controlHeight),
      );
      await tester.tap(find.text('Planned'));
      expect(taken, ['p']);
      expect(find.text('1'), findsOneWidget);
      expect(tester.getSize(find.byType(AppMenu)).width, AppMenu.minWidth);
    });

    testWidgets('the current choice has a check, and only then', (
      tester,
    ) async {
      await pumpMenu(tester, [
        MenuEntry(label: 'Recent', onPressed: () {}, selected: true),
        MenuEntry(label: 'Title', onPressed: () {}),
      ]);
      final checks = tester
          .widgetList<AppIcon>(find.byType(AppIcon))
          .where((icon) => icon.def == AppIcons.check);
      expect(checks, hasLength(1));
    });

    testWidgets('a menu without a current choice has no check column', (
      tester,
    ) async {
      await pumpMenu(tester, [
        MenuEntry(label: 'Open details', onPressed: () {}),
      ]);
      expect(find.byType(AppIcon), findsNothing);
    });

    testWidgets('removing is red', (tester) async {
      await pumpMenu(tester, [
        MenuEntry(
          label: 'Remove from list',
          onPressed: () {},
          destructive: true,
        ),
      ]);
      expect(
        tester.widget<Text>(find.text('Remove from list')).style!.color,
        Tokens.red,
      );
    });
  });

  group('popover', () {
    var picked = '';

    Future<void> pumpPopover(WidgetTester tester) {
      picked = '';
      return tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 100, top: 100),
                      child: AppPopover(
                        builder: (context, handle) => AppButton(
                          label: 'Sort',
                          kind: ButtonKind.secondary,
                          onPressed: handle.open,
                        ),
                        popoverBuilder: (context, handle) => AppMenu(
                          entries: [
                            MenuEntry(
                              label: 'Title',
                              onPressed: () {
                                picked = 'title';
                                handle.close();
                              },
                            ),
                          ],
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

    testWidgets('opens under its anchor', (tester) async {
      await pumpPopover(tester);
      expect(find.byType(AppMenu), findsNothing);
      await tester.tap(find.text('Sort'));
      await tester.pump();
      expect(find.byType(AppMenu), findsOneWidget);
      final anchor = tester.getRect(find.byType(AppButton));
      final menu = tester.getTopLeft(find.byType(AppMenu));
      expect(menu, Offset(anchor.left, anchor.bottom));
    });

    testWidgets('choosing a row runs it and closes', (tester) async {
      await pumpPopover(tester);
      await tester.tap(find.text('Sort'));
      await tester.pump();
      await tester.tap(find.text('Title'));
      await tester.pump();
      expect(picked, 'title');
      expect(find.byType(AppMenu), findsNothing);
    });

    testWidgets('a click outside closes it', (tester) async {
      await pumpPopover(tester);
      await tester.tap(find.text('Sort'));
      await tester.pump();
      await tester.tapAt(const Offset(600, 500));
      await tester.pump();
      expect(find.byType(AppMenu), findsNothing);
      expect(picked, '');
    });

    testWidgets('Escape closes it', (tester) async {
      await pumpPopover(tester);
      await tester.tap(find.text('Sort'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(AppMenu), findsNothing);
    });
  });
}
