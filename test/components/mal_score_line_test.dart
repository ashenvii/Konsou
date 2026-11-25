import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/mal_score_line.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/score_star.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('the gold star, the score in ink, a dot and when', (
    tester,
  ) async {
    await pumpWidget(tester, const MalScoreLine(score: 9.29, when: '2023'));
    expect(tester.widget<ScoreStar>(find.byType(ScoreStar)).color, Tokens.star);
    expect(tester.widget<Text>(find.text('9.29')).style?.color, Tokens.ink);
    expect(find.text('·'), findsOneWidget);
    expect(find.text('2023'), findsOneWidget);
  });

  testWidgets('no score from MAL is a question mark', (tester) async {
    await pumpWidget(tester, const MalScoreLine(score: null, when: '?'));
    expect(find.text('?'), findsNWidgets(2));
  });

  testWidgets('the strip card shows the score alone', (tester) async {
    await pumpWidget(tester, const MalScoreLine(score: 8.4));
    expect(find.text('8.40'), findsOneWidget);
    expect(find.text('·'), findsNothing);
  });

  testWidgets('a screen reader hears it as one line', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpWidget(tester, const MalScoreLine(score: 9.29, when: '2023'));
    expect(find.bySemanticsLabel('MAL score 9.29, 2023'), findsOneWidget);
    handle.dispose();
  });
}
