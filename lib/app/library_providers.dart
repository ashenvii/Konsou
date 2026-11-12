import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../library/entry_edits.dart';
import '../library/library_row.dart';
import '../library/library_view.dart';
import '../library/load_library.dart';
import 'entry_actions.dart';
import 'providers.dart';
import 'toast_host.dart';

part 'library_providers.g.dart';

/// Rows are reloaded at most this often while the background work saves
/// things. A reload reads about 6500 entries on the UI thread (100 to 150 ms),
/// so a short gap made the window stutter while the trickle ran.
const libraryReloadGap = Duration(seconds: 10);

/// The Library's rows, franchises folded. Reloads itself while the background
/// work saves details, matches and franchises. An edit reloads it at once with
/// `ref.invalidate`.
@riverpod
Future<List<LibraryRow>> libraryRows(Ref ref) async {
  final services = ref.watch(servicesProvider);
  Timer? pending;
  final listener = services.dataChanged.listen((_) {
    pending ??= Timer(libraryReloadGap, ref.invalidateSelf);
  });
  ref.onDispose(() {
    pending?.cancel();
    listener.cancel();
  });
  final databases = services.databases;
  return loadLibraryRows(databases, await readTitleLanguage(databases.record));
}

/// The edits a Library screen can make. Each one tells sync a change was made.
@Riverpod(keepAlive: true)
EntryEdits entryEdits(Ref ref) {
  final services = ref.watch(servicesProvider);
  return EntryEdits(
    databases: services.databases,
    onChanged: () => services.sync?.noteChange(),
  );
}

/// What screens call to change an entry: the edit, then the toast that tells
/// what came of it, then the check for earlier titles.
@Riverpod(keepAlive: true)
EntryActions entryActions(Ref ref) {
  final host = ref.watch(toastHostProvider.notifier);
  return EntryActions(
    databases: ref.watch(servicesProvider).databases,
    edits: ref.watch(entryEditsProvider),
    show: host.show,
    dismiss: host.dismiss,
    onEdited: () => ref.invalidate(libraryRowsProvider),
  );
}

/// The tab the Library is on, kept while the app runs.
@Riverpod(keepAlive: true)
class LibraryTabChoice extends _$LibraryTabChoice {
  @override
  LibraryTab build() => LibraryTab.all;

  void select(LibraryTab tab) {
    state = tab;
    // rows an edit left in view only stay until the tab changes
    ref.invalidate(libraryKeptProvider);
  }
}

/// Rows an edit moved out of the tab they are shown in. They stay in view
/// until the tab changes or the page is left, so the owner sees the change.
@riverpod
class LibraryKept extends _$LibraryKept {
  @override
  Set<String> build() => {};

  void keep(String entryId) => state = {...state, entryId};
}

/// The Library's sort, kept while the app runs.
@Riverpod(keepAlive: true)
class LibrarySortChoice extends _$LibrarySortChoice {
  @override
  LibrarySort build() => LibrarySort.recent;

  void select(LibrarySort sort) => state = sort;
}

const _layoutKey = 'library.layout';

/// Grid or list, remembered on this device. Grid until the user picks.
@Riverpod(keepAlive: true)
class LibraryLayoutChoice extends _$LibraryLayoutChoice {
  @override
  Future<LibraryLayout> build() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(
        _layoutKey,
      );
      return LibraryLayout.values.asNameMap()[saved] ?? LibraryLayout.grid;
    } on Exception {
      return LibraryLayout.grid;
    }
  }

  Future<void> select(LibraryLayout layout) async {
    state = AsyncData(layout);
    try {
      await (await SharedPreferences.getInstance()).setString(
        _layoutKey,
        layout.name,
      );
    } on Exception {
      // not remembered, but it still switches
    }
  }
}
