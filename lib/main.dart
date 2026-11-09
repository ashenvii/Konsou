import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import 'app/keys.dart';
import 'app/providers.dart';
import 'app/routes.dart';
import 'app/secure_token_store.dart';
import 'app/services.dart';
import 'data/databases.dart';
import 'design/tokens.dart';
import 'shell/native_window.dart';
import 'shell/window_config.dart';
import 'shell/window_memory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) await _setUpWindow();
  final folder = await getApplicationSupportDirectory();
  final services = Services(
    databases: await openDatabases(folder),
    coversFolder: Directory('${folder.path}${Platform.pathSeparator}covers'),
    keys: const Keys.fromBuild(),
    client: http.Client(),
    tokenStore: SecureTokenStore(),
    openBrowser: (url) => launchUrl(url, mode: LaunchMode.externalApplication),
  );
  runApp(
    ProviderScope(
      overrides: [servicesProvider.overrideWithValue(services)],
      child: KonsouApp(router: buildRouter(beforeClose: services.stop)),
    ),
  );
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
  const KonsouApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp.router(
      color: Tokens.ground,
      title: WindowConfig.title,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => DefaultTextStyle(
        style: const TextStyle(
          fontFamily: Tokens.sans,
          fontSize: Tokens.text3,
          color: Tokens.ink,
        ),
        child: child!,
      ),
    );
  }
}
