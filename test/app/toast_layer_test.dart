import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/entry_actions.dart';
import 'package:konsou/app/library_providers.dart';
import 'package:konsou/app/toast_host.dart';
import 'package:konsou/app/toast_layer.dart';
import 'package:konsou/components/app_checkbox.dart';
import 'package:konsou/components/earlier_review.dart';
import 'package:konsou/components/star_rating.dart';
import 'package:konsou/components/toast_timer.dart';
import 'package:konsou/components/toast_view.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/library/earlier_titles.dart';

import '../support/render_png.dart' show loadAppFonts;

class FakeActions implements EntryActions {
  final calls = <String>[];

  @override
  Future<void> rate(String entryId, int? score) async =>
      calls.add('rate $entryId $score');

  @override
  Future<void> acceptReview(
    ReviewOffer offer,
    List<EarlierTitle> chosen,
  ) async => calls.add('mark ${chosen.map((t) => t.malId).join(',')}');

  @override
  Future<void> notNow(ReviewOffer offer) async => calls.add('not now');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _titles = [
  EarlierTitle(malId: 1, name: 'First Season', isExtra: false, mediaType: 'tv'),
  EarlierTitle(
    malId: 2,
    name: 'Second Season',
    isExtra: false,
    startDate: '2020-04-01',
  ),
  EarlierTitle(malId: 10, name: 'The Movie', isExtra: true),
];

/// A widget test that closes any toast left showing, so no timer is left
/// pending, and that has semantics on so labels can be found.
void testToast(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    final semantics = tester.ensureSemantics();
    await body(tester);
    final scope = tester
        .element(find.byType(Overlay))
        .findAncestorWidgetOfExactType<UncontrolledProviderScope>();
    scope?.container.read(toastHostProvider.notifier).dismiss();
    await tester.pump();
    semantics.dispose();
  });
}

void main() {
  late FakeActions actions;
  late ProviderContainer container;

  setUp(() {
    actions = FakeActions();
    container = ProviderContainer(
      overrides: [entryActionsProvider.overrideWithValue(actions)],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpLayer(WidgetTester tester) async {
    // the real fonts, since the stars and the button share one row
    await loadAppFonts();
    tester.view
      ..physicalSize = const Size(900, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: [OverlayEntry(builder: (_) => const ToastLayer())],
          ),
        ),
      ),
    );
  }

  ToastHost host() => container.read(toastHostProvider.notifier);

  testToast('nothing shows until a toast is shown', (tester) async {
    await pumpLayer(tester);
    expect(find.byType(ToastView), findsNothing);
  });

  testToast('a toast sits at the bottom centre, 16 up, at most 480 wide', (
    tester,
  ) async {
    await pumpLayer(tester);
    host().show(ToastMessage('Completed'));
    await tester.pump();
    final box = tester.getRect(find.byType(ToastView));
    expect(box.bottom, 700 - Tokens.space4);
    expect(box.center.dx, 450);
    expect(box.width, lessThanOrEqualTo(Tokens.toastMaxWidth));
    host().show(ToastMessage('x ' * 400));
    await tester.pump();
    expect(tester.getRect(find.byType(ToastView)).width, Tokens.toastMaxWidth);
  });

  testToast('the X closes it', (tester) async {
    await pumpLayer(tester);
    host().show(ToastMessage('Completed'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pump();
    expect(find.byType(ToastView), findsNothing);
  });

  testToast('Undo runs the undo and closes the toast', (tester) async {
    await pumpLayer(tester);
    var undone = false;
    host().show(ToastMessage('Marked', undo: () async => undone = true));
    await tester.pump();
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(undone, isTrue);
    expect(find.byType(ToastView), findsNothing);
  });

  testToast('a toast without an undo has no Undo button', (tester) async {
    await pumpLayer(tester);
    host().show(ToastMessage('It has not aired yet.'));
    await tester.pump();
    expect(find.text('Undo'), findsNothing);
  });

  testToast('a toast goes after 4 seconds, 6 with an action', (tester) async {
    await pumpLayer(tester);
    host().show(ToastMessage('Not aired yet.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3900));
    expect(find.byType(ToastView), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ToastView), findsNothing);
    host().show(ToastMessage('Completed', undo: () async {}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5900));
    expect(find.byType(ToastView), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ToastView), findsNothing);
  });

  testToast('the pointer pauses the time and leaving carries on from there', (
    tester,
  ) async {
    await pumpLayer(tester);
    host().show(ToastMessage('Completed'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.byType(ToastView)));
    await tester.pump();
    expect(container.read(toastHostProvider).pointerOver, isTrue);
    await tester.pump(const Duration(seconds: 30));
    expect(find.byType(ToastView), findsOneWidget);
    await mouse.moveTo(const Offset(5, 5));
    await tester.pump();
    // one second was left when it stopped, not a fresh four
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(ToastView), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ToastView), findsNothing);
  });

  testToast('a star starts the time over but it stays held until the pointer '
      'leaves', (tester) async {
    await pumpLayer(tester);
    host().show(
      ToastMessage(
        'Completed. 3 earlier not marked.',
        review: const ReviewOffer(entryId: 'e9', titles: _titles),
        rateEntryId: 'e9',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.bySemanticsLabel('Rate 8')));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Rate 8'));
    await tester.pump();
    expect(host().time.share, 1);
    expect(host().time.running, isFalse);
    await tester.pump(const Duration(seconds: 30));
    expect(find.byType(ToastView), findsOneWidget);
    await mouse.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(host().time.running, isTrue);
    await tester.pump(const Duration(milliseconds: 5900));
    expect(find.byType(ToastView), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ToastView), findsNothing);
  });

  group('the review toast', () {
    Future<void> showReview(WidgetTester tester) async {
      await pumpLayer(tester);
      host().show(
        ToastMessage(
          'Completed. 3 earlier not marked.',
          review: const ReviewOffer(entryId: 'e9', titles: _titles),
          rateEntryId: 'e9',
        ),
      );
      await tester.pump();
    }

    testToast('the bar shows the time left and holds while review is open', (
      tester,
    ) async {
      await showReview(tester);
      expect(find.byType(ToastTimer), findsOneWidget);
      expect(host().time.running, isTrue);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump();
      expect(host().time.running, isFalse);
      // closing it without an answer carries on, it does not start over
      host().setReviewOpen(false);
      await tester.pump();
      expect(host().time.running, isTrue);
      expect(host().time.share, lessThan(1));
    });

    testToast('a review left alone is told it was missed; an answer is not', (
      tester,
    ) async {
      var missed = 0;
      await pumpLayer(tester);
      ToastMessage offer() => ToastMessage(
        'Completed. 3 earlier not marked.',
        review: const ReviewOffer(entryId: 'e9', titles: _titles),
        rateEntryId: 'e9',
        onMissed: () => missed++,
      );
      host().show(offer());
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pump();
      expect(missed, 1);
      // answered: the answer takes its place and nothing is missed
      host().show(offer());
      await tester.pump();
      host().answerReview(ToastMessage('Marked 3 earlier', rateEntryId: 'e9'));
      await tester.pump();
      host().dismiss();
      await tester.pump();
      expect(missed, 1);
      // an Undo of the finish is not a miss either
      host().show(
        ToastMessage(
          'Completed. 3 earlier not marked.',
          undo: () async {},
          review: const ReviewOffer(entryId: 'e9', titles: _titles),
          onMissed: () => missed++,
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(missed, 1);
      // timing out is
      host().show(offer());
      await tester.pump();
      await tester.pump(toastActionTime);
      expect(missed, 2);
    });

    testToast('review is a modal: the scrim catches clicks and closes it', (
      tester,
    ) async {
      var behind = 0;
      await loadAppFonts();
      tester.view
        ..physicalSize = const Size(900, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (_) => Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => behind++,
                        ),
                      ),
                      const Positioned.fill(child: ToastLayer()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      host().show(
        ToastMessage(
          'Completed. 3 earlier not marked.',
          review: const ReviewOffer(entryId: 'e9', titles: _titles),
          rateEntryId: 'e9',
        ),
      );
      await tester.pump();
      // before the review opens the page behind can be clicked
      await tester.tapAt(const Offset(20, 20));
      expect(behind, 1);
      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump();
      await tester.tapAt(const Offset(20, 20));
      await tester.pump();
      // the click went to the scrim, which closed the review, not to the page
      expect(behind, 1);
      expect(find.byType(EarlierReview), findsNothing);
      expect(container.read(toastHostProvider).reviewOpen, isFalse);
    });

    testToast('has ten stars and a Review word', (tester) async {
      await showReview(tester);
      expect(find.byType(StarRating), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testToast('a star rates the finished title', (tester) async {
      await showReview(tester);
      await tester.tap(find.bySemanticsLabel('Rate 8'));
      await tester.pump();
      expect(actions.calls, ['rate e9 8']);
      expect(container.read(toastHostProvider).rating, 8);
      expect(find.byType(ToastView), findsOneWidget);
    });

    testToast('the number follows the pointer, and the score can be cleared', (
      tester,
    ) async {
      await showReview(tester);
      // the caption is the last text in the rating; the others only hold width
      String? caption() => tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(StarRating),
              matching: find.byType(Text),
            ),
          )
          .last
          .data;
      final width = tester.getSize(find.byType(StarRating)).width;
      // nothing is said until the pointer or a score gives it something
      expect(caption(), '');
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.bySemanticsLabel('Rate 8')));
      await tester.pump();
      expect(caption(), '8');
      await tester.tap(find.bySemanticsLabel('Rate 8'));
      await tester.pump();
      expect(caption(), 'Clear');
      // the row is the same width whatever the caption, so nothing moves
      expect(tester.getSize(find.byType(StarRating)).width, width);
      await tester.tap(find.bySemanticsLabel('Rate 8'));
      await tester.pump();
      expect(actions.calls, ['rate e9 8', 'rate e9 null']);
    });

    testToast('Review opens the list: stories ticked, extras not', (
      tester,
    ) async {
      await showReview(tester);
      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(EarlierReview), findsOneWidget);
      expect(find.text('First Season'), findsOneWidget);
      expect(find.text('Extras'), findsOneWidget);
      expect(find.text('Mark 2'), findsOneWidget);
      expect(container.read(toastHostProvider).reviewOpen, isTrue);
    });

    testToast('the toast stays while review is open, however long', (
      tester,
    ) async {
      await showReview(tester);
      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(find.byType(ToastView), findsOneWidget);
    });

    testToast('ticking an extra changes the count; Mark sends the ticked', (
      tester,
    ) async {
      await showReview(tester);
      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump();
      // tick the extra through its checkbox
      final boxes = find.byType(AppCheckbox);
      await tester.tap(boxes.last);
      await tester.pump();
      expect(find.text('Mark 3'), findsOneWidget);
      await tester.tap(find.text('Mark 3'));
      await tester.pump();
      expect(actions.calls, ['mark 1,2,10']);
    });

    testToast('Not now reports it', (tester) async {
      await showReview(tester);
      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Not now'));
      await tester.pump();
      expect(actions.calls, ['not now']);
    });
  });
}
