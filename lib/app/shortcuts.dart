import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library/library_view.dart';
import '../screens/library/library_keys.dart';
import 'library_providers.dart';
import 'toast_host.dart';

class AppShortcut {
  const AppShortcut(this.name, this.keys, this.where);

  final String name;
  final String keys;
  final String where;
}

const appShortcuts = [
  AppShortcut('Undo', 'Ctrl+Z', 'While a toast with Undo shows'),
  AppShortcut('Find a title', 'Ctrl+F', 'Library'),
  AppShortcut('Show All', 'Alt+1', 'Library'),
  AppShortcut('Show Watching', 'Alt+2', 'Library'),
  AppShortcut('Show Planned', 'Alt+3', 'Library'),
  AppShortcut('Show Completed', 'Alt+4', 'Library'),
  AppShortcut('Show On hold', 'Alt+5', 'Library'),
  AppShortcut('Show Dropped', 'Alt+6', 'Library'),
  AppShortcut('Show Not interested', 'Alt+7', 'Library'),
  AppShortcut('Set Watching', '1', 'Library, on the hovered or focused row'),
  AppShortcut('Set Planned', '2', 'Library, on the hovered or focused row'),
  AppShortcut('Set Completed', '3', 'Library, on the hovered or focused row'),
  AppShortcut('Set On hold', '4', 'Library, on the hovered or focused row'),
  AppShortcut('Add an episode', '+', 'Library, on a watched title'),
  AppShortcut('Close a menu or popover', 'Esc', 'Anywhere one is open'),
];

class AppShortcuts extends ConsumerWidget {
  const AppShortcuts({
    super.key,
    required this.child,
    this.libraryOpen = false,
  });

  final Widget child;

  final bool libraryOpen;

  static const _numberKeys = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // the Library's keys wait while the review is open over it
    final reviewOpen = ref.watch(
      toastHostProvider.select((state) => state.reviewOpen),
    );
    final libraryActive = libraryOpen && !reviewOpen;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            ref.read(toastHostProvider.notifier).undoNewest(),
        if (libraryActive) ...{
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
              ref.read(libraryFindChoiceProvider.notifier).open(),
        },
        if (libraryActive)
          for (final (index, tab) in LibraryTab.values.indexed)
            SingleActivator(_numberKeys[index], alt: true): () =>
                ref.read(libraryTabChoiceProvider.notifier).select(tab),
      },
      // something always holds focus, so the keys are heard on a bare page
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        // keys on the Library's rows, which no text field below has used
        onKeyEvent: libraryActive
            ? (node, event) => handleLibraryKey(ref, event)
            : null,
        child: child,
      ),
    );
  }
}
