import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/load_progress.dart';
import 'package:konsou/app/load_wordmark.dart';
import 'package:konsou/design/tokens.dart';

const _details = LoadProgress(
  job: LoadJob.details,
  details: (done: 1240, total: 6499),
  covers: (done: 0, total: 6000),
);

void main() {
  late StreamController<LoadProgress> updates;

  setUp(() => updates = StreamController<LoadProgress>.broadcast());
  tearDown(() => updates.close());

  Future<void> show(
    WidgetTester tester, {
    LoadProgress start = const LoadProgress(),
  }) => tester.pumpWidget(
    WidgetsApp(
      color: Tokens.ground,
      builder: (context, _) => Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => Align(
              alignment: Alignment.topLeft,
              child: LoadWordmark(progress: start, updates: updates.stream),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> send(WidgetTester tester, LoadProgress progress) async {
    updates.add(progress);
    await tester.pump();
    await tester.pump();
    await tester.pump(Tokens.motionFlap * 2);
    await tester.pump();
  }

  bool countShown() => find.text(' / 6,499').evaluate().isNotEmpty;
  bool wordShown() => find.text('Konsou').evaluate().isNotEmpty;

  testWidgets('at rest it is the wordmark', (tester) async {
    await show(tester);
    expect(wordShown(), isTrue);
    expect(countShown(), isFalse);
  });

  testWidgets('it takes turns with the count while it loads', (tester) async {
    await show(tester);
    await send(tester, _details);
    expect(countShown(), isTrue);
    expect(wordShown(), isFalse);

    await tester.pump(Tokens.countTurn);
    await tester.pump();
    await tester.pump(Tokens.motionFlap * 2);
    await tester.pump();
    expect(wordShown(), isTrue);
    expect(countShown(), isFalse);

    await tester.pump(Tokens.wordmarkTurn);
    await tester.pump();
    await tester.pump(Tokens.motionFlap * 2);
    await tester.pump();
    expect(countShown(), isTrue);
  });

  testWidgets('when it is all in it says so, then rests on Konsou', (
    tester,
  ) async {
    await show(tester);
    await send(tester, _details);
    await send(tester, const LoadProgress(finished: true));
    expect(find.text('All loaded'), findsOneWidget);

    await tester.pump(Tokens.allLoadedHold);
    await tester.pump();
    await tester.pump(Tokens.motionFlap * 2);
    await tester.pump();
    expect(wordShown(), isTrue);
    await tester.pump(Tokens.countTurn * 3);
    expect(countShown(), isFalse);
  });

  testWidgets('waiting on MAL shows a pause mark beside the count', (
    tester,
  ) async {
    await show(tester);
    await send(
      tester,
      const LoadProgress(
        job: LoadJob.details,
        waiting: true,
        details: (done: 1240, total: 6499),
      ),
    );
    expect(find.text('‖ '), findsOneWidget);
  });

  testWidgets('a click while it loads lists each job', (tester) async {
    await show(tester, start: _details);
    await tester.pump();
    await tester.pump(Tokens.motionFlap * 2);
    await tester.pump();
    await tester.tap(find.byType(LoadWordmark));
    await tester.pump();
    await tester.pump(Tokens.motionOpen);
    expect(find.text('Loading your library'), findsOneWidget);
    expect(find.text('Loading details: 1,240 of 6,499.'), findsOneWidget);
    // the turns keep going, so stop them before the test ends
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with reduced motion the faces change in place', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => LoadWordmark(
                  progress: const LoadProgress(),
                  updates: updates.stream,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    updates.add(_details);
    await tester.pump();
    await tester.pump();
    expect(countShown(), isTrue);
    expect(wordShown(), isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
