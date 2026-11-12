import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/toast_host.dart';

const _review = ReviewOffer(entryId: 'a', titles: []);

void main() {
  late ProviderContainer container;
  late ToastHost host;

  ToastState state() => container.read(toastHostProvider);

  // no timer may outlive a test: close what is left
  void toastTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        await body(tester);
        host.dismiss(missed: false);
      });

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    host = container.read(toastHostProvider.notifier);
  });

  toastTest('a message closes after 4 seconds', (tester) async {
    host.show(ToastMessage('Hello'));
    await tester.pump(const Duration(milliseconds: 3900));
    expect(state().shown?.text, 'Hello');
    await tester.pump(const Duration(milliseconds: 200));
    expect(state().shown, isNull);
  });

  toastTest('a message with an action closes after 6 seconds', (tester) async {
    host.show(ToastMessage('Completed', undo: () async {}));
    await tester.pump(const Duration(milliseconds: 5900));
    expect(state().shown, isNotNull);
    await tester.pump(const Duration(milliseconds: 200));
    expect(state().shown, isNull);
  });

  toastTest('a new toast replaces the one showing and starts its time', (
    tester,
  ) async {
    host.show(ToastMessage('One'));
    await tester.pump(const Duration(seconds: 3));
    host.show(ToastMessage('Two'));
    expect(state().shown?.text, 'Two');
    await tester.pump(const Duration(seconds: 3));
    expect(state().shown?.text, 'Two');
  });

  toastTest('the pointer pauses the time; leaving carries on, not over', (
    tester,
  ) async {
    host.show(ToastMessage('Hello'));
    await tester.pump(const Duration(seconds: 3));
    host.setPointerOver(true);
    await tester.pump(const Duration(seconds: 30));
    expect(state().shown, isNotNull);
    host.setPointerOver(false);
    await tester.pump(const Duration(milliseconds: 900));
    expect(state().shown, isNotNull);
    await tester.pump(const Duration(milliseconds: 200));
    expect(state().shown, isNull);
  });

  toastTest('an open review pauses it even with the pointer away', (
    tester,
  ) async {
    host.show(ToastMessage('Completed', review: _review));
    host.setReviewOpen(true);
    await tester.pump(const Duration(minutes: 5));
    expect(state().shown, isNotNull);
    host.setReviewOpen(false);
    await tester.pump(const Duration(seconds: 6));
    expect(state().shown, isNull);
  });

  toastTest('it runs only when neither the pointer nor review holds it', (
    tester,
  ) async {
    host.show(ToastMessage('Completed', review: _review));
    host.setReviewOpen(true);
    host.setPointerOver(true);
    host.setReviewOpen(false);
    await tester.pump(const Duration(minutes: 1));
    expect(state().shown, isNotNull);
    host.setPointerOver(false);
    await tester.pump(const Duration(seconds: 6));
    expect(state().shown, isNull);
  });

  toastTest('a rating starts the time over, and stays held while the '
      'pointer is on it', (tester) async {
    host.show(ToastMessage('Completed', review: _review, rateEntryId: 'a'));
    await tester.pump(const Duration(seconds: 5));
    host.setPointerOver(true);
    host.rate(8);
    expect(state().rating, 8);
    expect(host.time.share, 1);
    await tester.pump(const Duration(minutes: 1));
    expect(state().shown, isNotNull);
    host.setPointerOver(false);
    await tester.pump(const Duration(milliseconds: 5900));
    expect(state().shown, isNotNull);
    await tester.pump(const Duration(milliseconds: 200));
    expect(state().shown, isNull);
  });

  toastTest('answering a review keeps the rating and starts over', (
    tester,
  ) async {
    host.show(ToastMessage('Completed', review: _review, rateEntryId: 'a'));
    host.rate(8);
    await tester.pump(const Duration(seconds: 5));
    host.setReviewOpen(true);
    host.answerReview(ToastMessage('Marked 2 earlier', rateEntryId: 'a'));
    expect(state().shown?.text, 'Marked 2 earlier');
    expect(state().rating, 8);
    expect(state().reviewOpen, isFalse);
    expect(host.time.share, 1);
    await tester.pump(const Duration(milliseconds: 3900));
    expect(state().shown, isNotNull);
    await tester.pump(const Duration(milliseconds: 200));
    expect(state().shown, isNull);
  });

  toastTest('a new toast clears the rating and holds of the old one', (
    tester,
  ) async {
    host.show(ToastMessage('Completed', review: _review, rateEntryId: 'a'));
    host.rate(8);
    host.setReviewOpen(true);
    host.dismiss(missed: false);
    host.show(ToastMessage('Next'));
    expect(state().rating, isNull);
    expect(state().reviewOpen, isFalse);
    await tester.pump(const Duration(seconds: 4));
    expect(state().shown, isNull);
  });

  toastTest('a review that goes unanswered is told it was missed', (
    tester,
  ) async {
    var missed = 0;
    ToastMessage offer() => ToastMessage(
      'Completed',
      review: _review,
      rateEntryId: 'a',
      onMissed: () => missed++,
    );
    host.show(offer());
    host.show(ToastMessage('Replaced it'));
    expect(missed, 1);
    host.show(offer());
    host.dismiss();
    expect(missed, 2);
    host.show(offer());
    await tester.pump(toastActionTime);
    expect(missed, 3);
    // answered, closed with Undo, or dismissed quietly: not missed
    host.show(offer());
    host.answerReview(ToastMessage('Saved for later.', rateEntryId: 'a'));
    host.dismiss();
    host.show(
      ToastMessage(
        'Completed',
        review: _review,
        undo: () async {},
        onMissed: () => missed++,
      ),
    );
    await host.undoNewest();
    expect(missed, 3);
  });

  toastTest('undoNewest runs the toast undo and closes it', (tester) async {
    var undone = 0;
    host.show(ToastMessage('Completed', undo: () async => undone++));
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
