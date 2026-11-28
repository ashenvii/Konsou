import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/held_lines.dart';
import 'package:konsou/components/skeleton.dart';
import 'package:konsou/components/skeleton_lines.dart';
import 'package:konsou/design/text_styles.dart';
import 'package:konsou/design/tokens.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 300, child: child),
  ),
);

void main() {
  final style = AppText.paragraph(Tokens.ink);

  testWidgets('loading shows a bar per line, the last one long', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(HeldLines('', style: style, lines: 3, loading: true)),
    );
    final widths = [
      for (final e in find.byType(Skeleton).evaluate())
        tester.getSize(find.byWidget(e.widget)).width,
    ];
    expect(widths, [300, 300, 180]);
  });

  testWidgets('loading keeps the height the text holds', (tester) async {
    Future<double> height({required bool loading}) async {
      await tester.pumpWidget(
        _host(HeldLines('A name', style: style, lines: 3, loading: loading)),
      );
      return tester.getSize(find.byType(HeldLines)).height;
    }

    expect(await height(loading: true), await height(loading: false));
  });

  testWidgets('the title lines are long over short', (tester) async {
    await tester.pumpWidget(_host(const SkeletonLines()));
    final widths = [
      for (final e in find.byType(Skeleton).evaluate())
        tester.getSize(find.byWidget(e.widget)).width,
    ];
    expect(widths, [180, 90]);
  });
}
