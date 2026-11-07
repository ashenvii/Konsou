import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'design/tokens.dart';
import 'shell/app_shell.dart';
import 'shell/native_window.dart';
import 'shell/window_config.dart';
import 'shell/window_memory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) await _setUpWindow();
  runApp(const KonsouApp());
}

Future<void> _setUpWindow() async {
  await windowManager.ensureInitialized();
  final saved = await WindowMemory.load();
  final options = WindowOptions(
    size: saved?.size ?? WindowConfig.startSize,
    center: saved == null,
    minimumSize: WindowConfig.minSize,
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Tokens.ground,
    title: WindowConfig.title,
  );
  await windowManager.waitUntilReadyToShow(options);
  if (saved == null) return;
  // The window is still hidden. Give it its saved placement now and let the
  // runner show it on the first drawn frame, so nothing flashes and Windows
  // keeps it on a connected screen.
  final placed = restoreWindowPlacement(
    title: WindowConfig.title,
    normal: saved.position & saved.size,
    scale: windowManager.getDevicePixelRatio(),
    maximized: saved.maximized,
  );
  if (!placed) {
    await windowManager.setPosition(saved.position);
    if (saved.maximized) await windowManager.maximize();
  }
}

class KonsouApp extends StatelessWidget {
  const KonsouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: Tokens.ground,
      title: WindowConfig.title,
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: const DefaultTextStyle(
        style: TextStyle(
          fontFamily: Tokens.sans,
          fontSize: Tokens.text3,
          color: Tokens.ink,
        ),
        child: AppShell(),
      ),
    );
  }
}
