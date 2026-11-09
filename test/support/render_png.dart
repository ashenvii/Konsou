import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts, so a rendered image shows the real type.
Future<void> loadAppFonts() async {
  const families = {
    'PlexSans': [
      'assets/fonts/IBMPlexSans-Regular.ttf',
      'assets/fonts/IBMPlexSans-Bold.ttf',
    ],
    'PlexMono': [
      'assets/fonts/IBMPlexMono-Regular.ttf',
      'assets/fonts/IBMPlexMono-Bold.ttf',
    ],
  };
  for (final MapEntry(:key, :value) in families.entries) {
    final loader = FontLoader(key);
    for (final path in value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
}

/// Draws [child] at [size] and saves it as a PNG at [path]. For screens the
/// owner looks at on a phone.
Future<void> renderPng(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required String path,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key: key, child: child));
  await tester.pump(const Duration(seconds: 2));
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
