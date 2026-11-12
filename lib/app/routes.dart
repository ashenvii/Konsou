import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../components/app_button.dart';
import '../gallery/gallery_screen.dart';
import '../screens/library/library_screen.dart';
import '../shell/app_rail.dart';
import '../shell/app_shell.dart';
import 'shortcuts.dart';
import 'title_page.dart';
import 'toast_layer.dart';

const galleryPath = '/gallery';

GoRouter buildRouter({Future<void> Function()? beforeClose}) {
  return GoRouter(
    initialLocation: libraryPath,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShortcuts(
          libraryOpen: state.matchedLocation == libraryPath,
          child: AppShell(
            beforeClose: beforeClose,
            rail: AppRail(
              location: state.matchedLocation,
              onSelect: (path) => context.go(path),
            ),
            overlay: (inset) => ToastLayer(leftInset: inset),
            child: child,
          ),
        ),
        routes: [
          for (final destination in [...railDestinations, settingsDestination])
            GoRoute(
              path: destination.path,
              pageBuilder: (context, state) => NoTransitionPage(
                child: switch (destination.path) {
                  libraryPath => LibraryScreen(
                    onDiscover: () => context.go(discoverPath),
                    // the Detail page is not built yet
                    onOpen: (_) {},
                  ),
                  settingsPath => TitlePage(
                    destination.label,
                    action: kDebugMode ? const _OpenGallery() : null,
                  ),
                  _ => TitlePage(destination.label),
                },
              ),
            ),
          if (kDebugMode)
            GoRoute(
              path: galleryPath,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: GalleryScreen()),
            ),
        ],
      ),
    ],
  );
}

class _OpenGallery extends StatelessWidget {
  const _OpenGallery();

  @override
  Widget build(BuildContext context) => AppButton(
    label: 'Open gallery',
    onPressed: () => context.go(galleryPath),
  );
}
