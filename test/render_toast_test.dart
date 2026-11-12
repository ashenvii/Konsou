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
                    builder: (_) => ColoredBox(
                      color: Tokens.ground,
                      child: Stack(
                        children: [
                          // something to dim: a page of blocks
                          Positioned.fill(
                            child: Wrap(
                              spacing: Tokens.space4,
                              runSpacing: Tokens.space4,
                              children: [
                                for (var i = 0; i < 24; i++)
                                  const SizedBox(
                                    width: Tokens.gridCardMinWidth,
                                    height: Tokens.gridCardMinWidth,
                                    child: ColoredBox(color: Tokens.surface),
                                  ),
                              ],
                            ),
                          ),
                          const Positioned.fill(child: ToastLayer()),
                        ],
                      ),
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

    host.show(ToastMessage('Completed', undo: () async {}));
    await tester.pump();
    await capturePng(tester, key, '$folder/toast_undo.png');

    host.show(ToastMessage('Not aired yet.'));
    await tester.pump();
    await capturePng(tester, key, '$folder/toast_message.png');

    host.show(
      ToastMessage(
        'Completed. 3 earlier not marked.',
        undo: () async {},
        rateEntryId: 'e',
        review: const ReviewOffer(
          entryId: 'e',
          titles: [
            EarlierTitle(
              malId: 1,
              name: 'Bakemonogatari',
              isExtra: false,
              mediaType: 'tv',
              startDate: '2009-07-03',
              episodes: 15,
            ),
            EarlierTitle(
              malId: 2,
              name: 'Kizumonogatari I: Tekketsu-hen',
              isExtra: false,
              mediaType: 'movie',
              startDate: '2016-01-08',
              episodes: 1,
              status: 'plan_to_watch',
            ),
            EarlierTitle(
              malId: 4,
              name: 'Nisemonogatari',
              isExtra: false,
              mediaType: 'tv',
              startDate: '2012-01-07',
              episodes: 11,
              status: 'dropped',
            ),
            EarlierTitle(
              malId: 5,
              name: 'Monogatari Series: Second Season',
              isExtra: false,
              mediaType: 'tv',
              startDate: '2013-07-06',
              episodes: 26,
            ),
            EarlierTitle(
              malId: 3,
              name: 'Hanamonogatari',
              isExtra: true,
              mediaType: 'special',
              startDate: '2014-08-16',
              episodes: 5,
            ),
            EarlierTitle(
              malId: 6,
              name: 'Bakemonogatari: Mayoi Snail Recap and a long title that runs over',
              isExtra: true,
              mediaType: 'ova',
              startDate: '2011-01-01',
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
