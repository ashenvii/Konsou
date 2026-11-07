import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/app_button.dart';
import 'package:konsou/components/app_checkbox.dart';
import 'package:konsou/components/app_tab.dart';
import 'package:konsou/components/count_badge.dart';
import 'package:konsou/components/panel.dart';
import 'package:konsou/gallery/gallery_screen.dart';

import 'support/pump_widget.dart';

void main() {
  // Add a line here for every component built, so the gallery cannot fall
  // behind the components folder.
  testWidgets('the gallery shows every component', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpWidget(
      tester,
      const SizedBox(width: 1200, height: 4000, child: GalleryScreen()),
    );
    expect(find.byType(AppButton), findsWidgets);
    expect(find.byType(AppTab), findsWidgets);
    expect(find.byType(CountBadge), findsWidgets);
    expect(find.byType(AppCheckbox), findsWidgets);
    expect(find.byType(Panel), findsWidgets);
  });

  testWidgets('clicking a tab selects it', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpWidget(
      tester,
      const SizedBox(width: 1200, height: 4000, child: GalleryScreen()),
    );
    await tester.tap(find.text('Top 10'));
    await tester.pump();
    final tab = tester.widget<AppTab>(find.widgetWithText(AppTab, 'Top 10'));
    expect(tab.selected, isTrue);
  });
}
