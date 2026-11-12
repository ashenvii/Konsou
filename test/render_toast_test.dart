import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/app/library_providers.dart';
import 'package:konsou/app/toast_host.dart';
import 'package:konsou/app/toast_layer.dart';
import 'package:konsou/design/tokens.dart';
import 'package:konsou/library/earlier_titles.dart';

import 'app/toast_layer_test.dart' show FakeActions;
import 'support/render_png.dart';

/// Renders the toast and the review to PNGs for looking at. Does nothing in
/// `check`. Set KONSOU_SHOTS to an output folder and run this file.
void main() {
  final folder = Platform.environment['KONSOU_SHOTS'];

  testWidgets('render the toast states', (tester) async {
    await loadAppFonts();
    final container = ProviderContainer(
      overrides: [entryActionsProvider.overrideWithValue(FakeActions())],
    );
    addTearDown(container.dispose);
    tester.view
      ..physicalSize = const Size(900, 500)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: const TextStyle(fontFamily: Tokens.sans),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (_) => const ColoredBox(
                      color: Tokens.ground,
                      child: ToastLayer(child: SizedBox.expand()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final host = container.read(toastHostProvider.notifier);

    host.show(ToastMessage('Marked as Completed', undo: () async {}));
    await tester.pump();
    await capturePng(tester, key, '$folder/toast_undo.png');

    host.show(ToastMessage('It has not aired yet.'));
    await tester.pump();
    await capturePng(tester, key, '$folder/toast_message.png');

    host.show(
      ToastMessage(
        'Frieren Season 2 completed. 3 earlier titles are not marked.',
        undo: () async {},
        review: const ReviewOffer(
          entryId: 'e',
          titles: [
            EarlierTitle(
              malId: 1,
              name: 'Frieren Season 1',
              isExtra: false,
              mediaType: 'tv',
              startDate: '2023-09-29',
            ),
            EarlierTitle(
              malId: 2,
              name: 'Frieren: Specials',
              isExtra: false,
              mediaType: 'tv',
              startDate: '2024-01-01',
            ),
            EarlierTitle(
              malId: 3,
              name: 'Frieren: Recap',
              isExtra: true,
              mediaType: 'special',
              startDate: '2023-12-01',
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await capturePng(tester, key, '$folder/toast_review.png');

    await tester.tap(find.text('Review'));
    await tester.pump();
    await tester.pump();
    await capturePng(tester, key, '$folder/toast_review_open.png');

    host.dismiss();
    await tester.pump();
  }, skip: folder == null);
}
