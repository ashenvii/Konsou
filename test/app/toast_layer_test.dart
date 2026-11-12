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
import 'package:konsou/components/toast_view.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/library/earlier_titles.dart';

class FakeActions implements EntryActions {
  final calls = <String>[];

  @override
  Future<void> rate(String entryId, int? score) async =>
      calls.add('rate $entryId $score');

  @override
  Future<void> acceptReview(List<EarlierTitle> titles) async =>
      calls.add('mark ${titles.map((t) => t.malId).join(',')}');

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
                builder: (_) => const ToastLayer(child: SizedBox.expand()),
              ),
            ],
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
    host().show(ToastMessage('Marked as Completed'));
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
    host().show(ToastMessage('Marked as Completed'));
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

  testToast('the pointer on the toast holds its timer', (tester) async {
    await pumpLayer(tester);
    host().show(ToastMessage('Marked'));
    await tester.pump();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.byType(ToastView)));
    await tester.pump();
    expect(container.read(toastHostProvider).pointerOver, isTrue);
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(ToastView), findsOneWidget);
    await mouse.moveTo(const Offset(5, 5));
    await tester.pump();
    await tester.pump(toastMessageTime);
    expect(find.byType(ToastView), findsNothing);
  });

  group('the review toast', () {
    Future<void> showReview(WidgetTester tester) async {
      await pumpLayer(tester);
      host().show(
        ToastMessage(
          'Show completed. 3 earlier titles are not marked.',
          review: const ReviewOffer(entryId: 'e9', titles: _titles),
        ),
      );
      await tester.pump();
    }

    testToast('has ten stars and a Review button', (tester) async {
      await showReview(tester);
      expect(find.byType(StarRating), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testToast('a star rates the finished title and the message follows', (
      tester,
    ) async {
      await showReview(tester);
      await tester.tap(find.bySemanticsLabel('Rate 8'));
      await tester.pump();
      expect(actions.calls, ['rate e9 8']);
      expect(find.text('Rated 8'), findsOneWidget);
      expect(find.byType(ToastView), findsOneWidget);
    });

    testToast('the number follows the pointer, and the score can be cleared', (
      tester,
    ) async {
      await showReview(tester);
      expect(find.text('Rate it'), findsOneWidget);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.bySemanticsLabel('Rate 8')));
      await tester.pump();
      expect(find.text('8'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Rate 8'));
      await tester.pump();
      expect(find.text('Clear'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Rate 8'));
      await tester.pump();
      expect(actions.calls, ['rate e9 8', 'rate e9 null']);
      expect(find.text('Rated 8'), findsNothing);
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
      expect(find.text('Mark 2 completed'), findsOneWidget);
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
      expect(find.text('Mark 3 completed'), findsOneWidget);
      await tester.tap(find.text('Mark 3 completed'));
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
