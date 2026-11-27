import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/providers.dart';
import 'package:konsou/app/score_fill.dart';

void main() {
  late List<String> events;

  Future<void> pump(
    WidgetTester tester, {
    required bool shown,
    required bool pending,
    int? malId = 7,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        detailOnScreenProvider(malId ?? 0, lane: Lane.screen).overrideWith((
          ref,
        ) async {
          events.add('fetch');
          ref.onDispose(() => events.add('left'));
        }),
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: shown
            ? ScoreFill(
                malId: malId,
                pending: pending,
                child: const Text('card'),
              )
            : const SizedBox(),
      ),
    ),
  );

  setUp(() => events = []);

  testWidgets('a card whose score is pending asks for its title while shown', (
    tester,
  ) async {
    await pump(tester, shown: true, pending: true);
    await tester.pump();
    expect(events, ['fetch']);
    expect(find.text('card'), findsOneWidget);
  });

  testWidgets('scrolled out of the tree, it lets the request go', (
    tester,
  ) async {
    await pump(tester, shown: true, pending: true);
    await tester.pump();
    await pump(tester, shown: false, pending: true);
    await tester.pump();
    expect(events, ['fetch', 'left']);
  });

  testWidgets('a card with its score asks for nothing', (tester) async {
    await pump(tester, shown: true, pending: false);
    await tester.pump();
    expect(events, isEmpty);
  });

  testWidgets('a card with no MAL page asks for nothing', (tester) async {
    await pump(tester, shown: true, pending: true, malId: null);
    await tester.pump();
    expect(events, isEmpty);
  });
}
