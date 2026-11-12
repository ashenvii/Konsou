import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/countdown.dart';

void main() {
  const second = Duration(seconds: 1);

  testWidgets('it runs down, calls onDone once, and the share follows', (
    tester,
  ) async {
    var done = 0;
    final countdown = Countdown(onDone: () => done++);
    addTearDown(countdown.dispose);
    countdown.start(const Duration(seconds: 4));
    expect(countdown.running, isTrue);
    expect(countdown.share, 1);
    await tester.pump(second);
    expect(countdown.share, closeTo(0.75, 0.01));
    await tester.pump(const Duration(seconds: 3));
    expect(done, 1);
    expect(countdown.running, isFalse);
    expect(countdown.share, 0);
  });

  testWidgets('pause keeps what is left and resume carries on from it', (
    tester,
  ) async {
    var done = 0;
    final countdown = Countdown(onDone: () => done++);
    addTearDown(countdown.dispose);
    countdown.start(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 3));
    countdown.pause();
    await tester.pump(const Duration(seconds: 30));
    expect(done, 0);
    expect(countdown.left, second);
    countdown.resume();
    await tester.pump(second);
    expect(done, 1);
  });

  testWidgets('restart goes back to full, and cancel forgets it', (
    tester,
  ) async {
    var done = 0;
    final countdown = Countdown(onDone: () => done++);
    addTearDown(countdown.dispose);
    countdown.start(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 3));
    countdown.restart();
    expect(countdown.share, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(done, 0);
    countdown.cancel();
    await tester.pump(const Duration(seconds: 10));
    expect(done, 0);
    expect(countdown.started, isFalse);
  });

  testWidgets('the builder follows it frame by frame and stops with it', (
    tester,
  ) async {
    final countdown = Countdown(onDone: () {});
    addTearDown(countdown.dispose);
    final seen = <double>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CountdownBuilder(
          countdown: countdown,
          builder: (context, share, running) {
            seen.add(share);
            return const SizedBox();
          },
        ),
      ),
    );
    countdown.start(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(seen.last, closeTo(0.5, 0.05));
    countdown.pause();
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
