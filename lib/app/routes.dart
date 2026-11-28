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
import 'quiet_page.dart';
import 'quick_search_providers.dart';
import 'shortcuts.dart';
import 'title_page.dart';
import 'toast_layer.dart';

/// Route of the component gallery.
const galleryPath = '/gallery';

/// Route of a title's page by MAL id, with the entry to show if given.
String titlePath(int malId, {String? entryId}) => Uri(
  path: '/title/$malId',
  queryParameters: entryId == null ? null : {'entry': entryId},
).toString();

/// Route of an entry's own page, for an entry with no MAL page.
String entryPath(String entryId) => '/entry/$entryId';

/// A title's page when it has a MAL page, else the entry's own page.
String detailPath({int? malId, String? entryId}) => switch (malId) {
  final malId? => titlePath(malId, entryId: entryId),
  null => entryPath(entryId!),
};

/// The page route for a Library row.
String detailPathFor(LibraryRow row) =>
    detailPath(malId: row.malId, entryId: row.entryId);

DetailScreen _detailScreen(BuildContext context, GoRouterState state) {
  void back() => goBack(context);
  void openTitle(int malId, {String? entryId}) =>
      context.push(titlePath(malId, entryId: entryId));
  // the picker takes this page's place, so Back does not return to a title
  // the entry no longer belongs to
  void showPicker(String entryId) =>
      context.pushReplacement(entryPath(entryId));
  final entryId = state.pathParameters['entryId'];
  return entryId != null
      ? DetailScreen.entry(
          entryId,
          onBack: back,
          onOpenTitle: openTitle,
          onShowPicker: showPicker,
        )
      : DetailScreen.title(
          int.parse(state.pathParameters['malId']!),
          entryId: state.uri.queryParameters['entry'],
          onBack: back,
          onOpenTitle: openTitle,
          onShowPicker: showPicker,
        );
}

/// The app's routes: the shell and its pages, title pages and the gallery.
GoRouter buildRouter({
  Future<void> Function()? beforeClose,
  VoidCallback? onFocus,
  Widget? wordmark,
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
            onFocus: onFocus,
            openSupport: openSupport,
            wordmark: wordmark,
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
                QuickSearchLayer(
                  onBrowse: () => context.go(discoverPath),
                  onOpen: (row) => context.push(
                    detailPath(malId: row.malId, entryId: row.entryId),
                  ),
                ),
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
              pageBuilder: (context, state) => QuietPage(
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
          for (final path in ['/title/:malId', '/entry/:entryId'])
            GoRoute(
              path: path,
              pageBuilder: (context, state) => QuietPage(
                // a page pushed over another of its kind is a new page
                key: state.pageKey,
                child: _detailScreen(context, state),
              ),
            ),
          if (kDebugMode)
            GoRoute(
              path: galleryPath,
              pageBuilder: (context, state) =>
                  const QuietPage(child: GalleryScreen()),
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
