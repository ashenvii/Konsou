import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/shortcuts.dart';
import 'package:konsou/app/toast_host.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: AppShortcuts(child: SizedBox.expand()),
      ),
    ),
  );

  testWidgets('Ctrl+Z runs the Undo of the toast showing', (tester) async {
    await pumpApp(tester);
    var undone = 0;
    container
        .read(toastHostProvider.notifier)
        .show(ToastMessage('Marked', undo: () async => undone++));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(undone, 1);
    expect(container.read(toastHostProvider).shown, isNull);
  });

  testWidgets('Ctrl+Z with no toast does nothing', (tester) async {
    await pumpApp(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(container.read(toastHostProvider).shown, isNull);
  });

  testWidgets('a toast with no Undo is left alone', (tester) async {
    await pumpApp(tester);
    container.read(toastHostProvider.notifier).show(ToastMessage('Not aired'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(container.read(toastHostProvider).shown, isNotNull);
    container.read(toastHostProvider.notifier).dismiss();
  });

  test('every shortcut is listed once', () {
    final keys = appShortcuts.map(
      (shortcut) => '${shortcut.keys} ${shortcut.where}',
    );
    expect(keys.toSet().length, appShortcuts.length);
    expect(appShortcuts.first.keys, 'Ctrl+Z');
  });
}
