import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts, so a rendered image shows the real type.
Future<void> loadAppFonts() async {
  const families = {
    'PlexSansJP': [
      'assets/fonts/IBMPlexSansJP-Regular.ttf',
      'assets/fonts/IBMPlexSansJP-Bold.ttf',
    ],
    'ChakraPetch': ['assets/fonts/ChakraPetch-SemiBold.ttf'],
    'ShareTechMono': ['assets/fonts/ShareTechMono-Regular.ttf'],
  };
  for (final MapEntry(:key, :value) in families.entries) {
    final loader = FontLoader(key);
    for (final path in value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
  // Flutter 3.50 tells the framework about new fonts a moment later, and the
  // frame that asks for would land after the test ends and fail it
  await TestWidgetsFlutterBinding.instance.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
}

/// Draws [child] at [size] and saves it as a PNG at [path]. For screens the
/// owner looks at on a phone.
/// Renders [child] at [size] and saves it at [path]. Returns the repaint
/// boundary's key, so a later state can be captured too (`capturePng`).
Future<GlobalKey> renderPng(
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
  // a scrollbar shows its thumb one frame after the first layout
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await capturePng(tester, key, path);
  return key;
}

/// Saves what the repaint boundary under [key] shows as a PNG at [path].
Future<void> capturePng(WidgetTester tester, GlobalKey key, String path) async {
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
