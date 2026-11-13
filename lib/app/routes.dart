import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/app_button.dart';
import '../gallery/gallery_screen.dart';
import '../library/library_row.dart';
import '../screens/detail/detail_screen.dart';
import '../screens/library/library_screen.dart';
import '../shell/app_rail.dart';
import '../shell/app_shell.dart';
import 'quick_search_layer.dart';
import 'quick_search_providers.dart';
import 'shortcuts.dart';
import 'title_page.dart';
import 'toast_layer.dart';

const galleryPath = '/gallery';

String titlePath(int malId, {String? entryId}) => Uri(
  path: '/title/$malId',
  queryParameters: entryId == null ? null : {'entry': entryId},
).toString();

String entryPath(String entryId) => '/entry/$entryId';

String detailPathFor(LibraryRow row) => switch (row.malId) {
  final malId? => titlePath(malId, entryId: row.entryId),
  null => entryPath(row.entryId),
};

GoRouter buildRouter({
  Future<void> Function()? beforeClose,
  Future<void> Function()? openSupport,
}) {
  return GoRouter(
    initialLocation: libraryPath,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShortcuts(
          libraryOpen: state.matchedLocation == libraryPath,
          child: AppShell(
            beforeClose: beforeClose,
            openSupport: openSupport,
            onSearch: () =>
                ProviderScope.containerOf(context)
                    .read(quickSearchProvider.notifier)
                    .open(),
            rail: AppRail(
              location: state.matchedLocation,
              onSelect: (path) => context.go(path),
            ),
            overlay: (inset) => Stack(
              children: [
                QuickSearchLayer(onBrowse: () => context.go(discoverPath)),
                ToastLayer(leftInset: inset),
              ],
            ),
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
                    onOpen: (row) => context.push(detailPathFor(row)),
                  ),
                  settingsPath => TitlePage(
                    destination.label,
                    action: kDebugMode ? const _OpenGallery() : null,
                  ),
                  _ => TitlePage(destination.label),
                },
              ),
            ),
          GoRoute(
            path: '/title/:malId',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DetailScreen.title(
                int.parse(state.pathParameters['malId']!),
                entryId: state.uri.queryParameters['entry'],
              ),
            ),
          ),
          GoRoute(
            path: '/entry/:entryId',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DetailScreen.entry(state.pathParameters['entryId']!),
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
