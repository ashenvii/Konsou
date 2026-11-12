import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/toast_host.dart';

const _review = ReviewOffer(entryId: 'a', titles: []);

void main() {
  late ProviderContainer container;
  late ToastHost host;

  ToastState state() => container.read(toastHostProvider);

  // no timer may outlive a test: close what is left, and what waited behind it
  void toastTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        await body(tester);
        host.dismiss();
        host.dismiss();
      });

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    host = container.read(toastHostProvider.notifier);
  });

  toastTest('a message closes after 5 seconds', (tester) async {
    host.show(ToastMessage('Hello'));
    await tester.pump(const Duration(seconds: 4));
    expect(state().shown?.text, 'Hello');
    await tester.pump(const Duration(seconds: 1));
    expect(state().shown, isNull);
  });

  toastTest('a message with an action closes after 8 seconds', (tester) async {
    host.show(ToastMessage('Marked as Completed', undo: () async {}));
    await tester.pump(const Duration(seconds: 7));
    expect(state().shown, isNotNull);
    await tester.pump(const Duration(seconds: 1));
    expect(state().shown, isNull);
  });

  toastTest('a new toast replaces the one showing', (tester) async {
    host.show(ToastMessage('One'));
    host.show(ToastMessage('Two'));
    expect(state().shown?.text, 'Two');
  });

  toastTest('the pointer on the toast stops the timer; leaving restarts it', (
    tester,
  ) async {
    host.show(ToastMessage('Hello'));
    host.setPointerOver(true);
    await tester.pump(const Duration(seconds: 30));
    expect(state().shown, isNotNull);
    host.setPointerOver(false);
    await tester.pump(const Duration(seconds: 4));
    expect(state().shown, isNotNull);
    await tester.pump(const Duration(seconds: 1));
    expect(state().shown, isNull);
  });

  toastTest('an open review stops the timer even with the pointer away', (
    tester,
  ) async {
    host.show(ToastMessage('Show completed', review: _review));
    host.setReviewOpen(true);
    await tester.pump(const Duration(minutes: 5));
    expect(state().shown, isNotNull);
    host.setReviewOpen(false);
    await tester.pump(const Duration(seconds: 8));
    expect(state().shown, isNull);
  });

  toastTest('it closes only when neither the pointer nor review holds it', (
    tester,
  ) async {
    host.show(ToastMessage('Show completed', review: _review));
    host.setReviewOpen(true);
    host.setPointerOver(true);
    host.setReviewOpen(false);
    await tester.pump(const Duration(minutes: 1));
    expect(state().shown, isNotNull);
    host.setPointerOver(false);
    await tester.pump(const Duration(seconds: 8));
    expect(state().shown, isNull);
  });

  toastTest('a rating does not close the toast or restart its timer', (
    tester,
  ) async {
    host.show(ToastMessage('Show completed', review: _review));
    await tester.pump(const Duration(seconds: 6));
    host.rate(8);
    expect(state().rating, 8);
    expect(state().shown, isNotNull);
    await tester.pump(const Duration(seconds: 2));
    expect(state().shown, isNull);
  });

  toastTest('the review toast is not replaced; others wait behind it', (
    tester,
  ) async {
    host.show(ToastMessage('Show completed', review: _review));
    host.show(ToastMessage('Later'));
    expect(state().shown?.review, isNotNull);
    host.dismiss();
    expect(state().shown?.text, 'Later');
  });

  toastTest('only the newest waiting message is kept', (tester) async {
    host.show(ToastMessage('Show completed', review: _review));
    host.show(ToastMessage('Second'));
    host.show(ToastMessage('Third'));
    host.dismiss();
    expect(state().shown?.text, 'Third');
    host.dismiss();
    expect(state().shown, isNull);
  });

  toastTest('the review toast times out and lets the waiting one in', (
    tester,
  ) async {
    host.show(ToastMessage('Show completed', review: _review));
    host.show(ToastMessage('Later'));
    await tester.pump(const Duration(seconds: 8));
    expect(state().shown?.text, 'Later');
  });

  toastTest('a new toast clears the rating and holds of the old one', (
    tester,
  ) async {
    host.show(ToastMessage('Show completed', review: _review));
    host.rate(8);
    host.setReviewOpen(true);
    host.dismiss();
    host.show(ToastMessage('Next'));
    expect(state().rating, isNull);
    await tester.pump(const Duration(seconds: 5));
    expect(state().shown, isNull);
  });

  toastTest('undoNewest runs the toast undo and closes it', (tester) async {
    var undone = 0;
    host.show(ToastMessage('Marked', undo: () async => undone++));
    expect(await host.undoNewest(), isTrue);
    expect(undone, 1);
    expect(state().shown, isNull);
  });

  toastTest('undoNewest does nothing when the toast has no undo', (
    tester,
  ) async {
    host.show(ToastMessage('Plain'));
    expect(await host.undoNewest(), isFalse);
    expect(state().shown?.text, 'Plain');
  });
}
