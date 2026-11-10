import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/count_badge.dart';
import 'package:konsou/design/tokens.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('is 16 tall, at least 16 wide, and mint', (tester) async {
    await pumpWidget(tester, const CountBadge(5));
    final size = tester.getSize(find.byType(CountBadge));
    // Tests draw text with a fixed-width test font, so only the floor is exact.
    expect(size.width, greaterThanOrEqualTo(Tokens.badgeSize));
    expect(size.height, Tokens.badgeSize);
    expect(fillOf(tester, find.byType(CountBadge)), Tokens.mint);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('wider numbers grow sideways only', (tester) async {
    await pumpWidget(tester, const CountBadge(42));
    final size = tester.getSize(find.byType(CountBadge));
    expect(size.width, greaterThanOrEqualTo(Tokens.badgeSize));
    expect(size.height, Tokens.badgeSize);
  });

  testWidgets('a big count shows in full', (tester) async {
    await pumpWidget(tester, const CountBadge(6481));
    expect(find.text('6481'), findsOneWidget);
  });
}
