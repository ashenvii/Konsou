import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/skeleton.dart';

Widget host({required bool still, required Widget child}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: child,
  ),
);

void main() {
  testWidgets('it sweeps while animations are on and stops when it goes', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        still: false,
        child: const Row(
          children: [
            Skeleton(width: 40, height: 60),
            Skeleton(width: 40, height: 60),
          ],
        ),
      ),
    );
    expect(SkeletonClock.instance.ticking, isTrue);
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(SkeletonClock.instance.phase, inInclusiveRange(0, 1));
    await tester.pumpWidget(const SizedBox());
    expect(SkeletonClock.instance.ticking, isFalse);
  });

  testWidgets('it stays still when the system turns animations off', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(still: true, child: const Skeleton(width: 40, height: 60)),
    );
    expect(SkeletonClock.instance.ticking, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
