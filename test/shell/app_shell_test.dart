import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/hover_mark.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/shell/app_shell.dart';

import '../support/render_png.dart' show loadAppFonts;

void main() {
  // An aligned Container once filled the whole bar, so its fill hid the
  // wordmark, the bell, the heart and the window buttons.
  for (final width in [900.0, 1100.0, 1600.0]) {
    testWidgets('the search well keeps its own size at a window $width wide', (
      tester,
    ) async {
      await loadAppFonts();
      tester.view.physicalSize = Size(width, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 300)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AppShell(child: Container()),
          ),
        ),
      );
      await tester.pump();
      final well = find
          .descendant(
            of: find.byType(HoverMark),
            matching: find.byType(Container),
          )
          .first;
      final size = tester.getSize(well);
      expect(size.width, Tokens.quickSearchWidth);
      expect(size.height, Tokens.quickSearchHeight);
      // centred in the window
      expect(tester.getCenter(well).dx, closeTo(width / 2, 1));
    });
  }

  testWidgets('hovering the search well lights the live edge', (tester) async {
    await loadAppFonts();
    tester.view.physicalSize = const Size(1100, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1100, 300)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppShell(child: Container()),
        ),
      ),
    );
    await tester.pump();
    final mark = find.byType(HoverMark);
    expect(tester.widget<HoverMark>(mark).on, isFalse);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(5, 250));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(mark));
    await tester.pump();
    expect(tester.widget<HoverMark>(mark).on, isTrue);
    await mouse.moveTo(const Offset(5, 250));
    await tester.pump();
    expect(tester.widget<HoverMark>(mark).on, isFalse);
  });
}
