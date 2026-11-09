import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import 'app/keys.dart';
import 'app/secure_token_store.dart';
import 'app/services.dart';
import 'data/databases.dart';

import 'design/tokens.dart';
import 'gallery/gallery_screen.dart';
import 'shell/app_shell.dart';
import 'shell/native_window.dart';
import 'shell/window_config.dart';
import 'shell/window_memory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) await _setUpWindow();
  final services = Services(
    databases: await openDatabases(await getApplicationSupportDirectory()),
    keys: const Keys.fromBuild(),
    client: http.Client(),
    tokenStore: SecureTokenStore(),
    openBrowser: (url) => launchUrl(url, mode: LaunchMode.externalApplication),
  );
  runApp(KonsouApp(services: services));
  services.start();
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
  const KonsouApp({super.key, required this.services});

  final Services services;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: Tokens.ground,
      title: WindowConfig.title,
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: Tokens.sans,
          fontSize: Tokens.text3,
          color: Tokens.ink,
        ),
        child: AppShell(
          beforeClose: services.stop,
          child: const _FirstScreen(),
        ),
      ),
    );
  }
}

/// The gallery is the first screen in debug builds.
class _FirstScreen extends StatelessWidget {
  const _FirstScreen();

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) return const GalleryScreen();
    return const Center(
      child: Text(
        'Window shell. Nothing here yet.',
        style: TextStyle(
          fontFamily: Tokens.mono,
          fontSize: Tokens.text2,
          color: Tokens.inkSoft,
        ),
      ),
    );
  }
}
