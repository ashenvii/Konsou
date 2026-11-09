import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/status_mark.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/icons/app_icon.dart';
import 'package:konsou/library/entry_status.dart';

import '../support/pump_widget.dart';

void main() {
  test('every status has its own icon', () {
    final icons = {
      for (final status in EntryStatus.values) StatusMark.iconFor(status),
    };
    expect(icons, hasLength(EntryStatus.values.length));
  });

  testWidgets('only Completed is coloured, the rest are ink', (tester) async {
    for (final status in EntryStatus.values) {
      await pumpWidget(tester, StatusMark(status));
      final icon = tester.widget<AppIcon>(find.byType(AppIcon));
      expect(
        icon.color,
        status == EntryStatus.completed ? Tokens.mint : Tokens.ink,
        reason: status.name,
      );
    }
  });

  testWidgets('it is the small icon size', (tester) async {
    await pumpWidget(tester, const StatusMark(EntryStatus.watching));
    expect(
      tester.getSize(find.byType(AppIcon)),
      const Size.square(Tokens.iconSize),
    );
  });

  testWidgets('a muted ink can be passed in', (tester) async {
    await pumpWidget(
      tester,
      const StatusMark(EntryStatus.dropped, color: Tokens.inkMuted),
    );
    expect(tester.widget<AppIcon>(find.byType(AppIcon)).color, Tokens.inkMuted);
  });
}
