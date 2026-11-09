import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/components/cover_image.dart';
import 'package:konsou/design/tokens.dart';

import '../support/pump_widget.dart';

void main() {
  testWidgets('without a file it is a blank surface square, 2:3', (
    tester,
  ) async {
    await pumpWidget(tester, const CoverImage(width: 40));
    expect(tester.getSize(find.byType(CoverImage)), const Size(40, 60));
    expect(find.byType(Image), findsNothing);
    expect(fillOf(tester, find.byType(CoverImage)), Tokens.surface);
  });

  testWidgets('with a file it draws that file at the same size', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('konsou_cover_image');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/1.webp')..writeAsBytesSync([1, 2, 3]);
    await pumpWidget(tester, CoverImage(width: 168, file: file));
    expect(tester.getSize(find.byType(CoverImage)), const Size(168, 252));
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as ResizeImage).imageProvider, isA<FileImage>());
  });

  test('the height is one and a half widths', () {
    expect(CoverImage.heightFor(200), 300);
  });
}
