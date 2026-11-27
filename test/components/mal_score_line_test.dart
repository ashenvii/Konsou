import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/mal_score_line.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/score_star.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('the gold star and the score in ink, nothing else', (
    tester,
  ) async {
    await pumpWidget(tester, const MalScoreLine(score: 9.29));
    expect(tester.widget<ScoreStar>(find.byType(ScoreStar)).color, Tokens.star);
    expect(tester.widget<Text>(find.text('9.29')).style?.color, Tokens.ink);
    expect(find.text('·'), findsNothing);
  });

  testWidgets('no score from MAL is a question mark', (tester) async {
    await pumpWidget(tester, const MalScoreLine(score: null));
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('a screen reader hears it as one line', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpWidget(tester, const MalScoreLine(score: 9.29));
    expect(find.bySemanticsLabel('MAL score 9.29'), findsOneWidget);
    handle.dispose();
  });
}
