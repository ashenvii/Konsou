import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'toast_host.dart';

/// One keyboard shortcut as the app lists it: what it does, its keys as shown
/// to the user, and where it works.
class AppShortcut {
  const AppShortcut(this.name, this.keys, this.where);

  final String name;
  final String keys;
  final String where;
}

/// Every shortcut in the app, listed once. Settings will show this list, read
/// only. A new shortcut is added here as well as where it is bound.
const appShortcuts = [
  AppShortcut('Undo', 'Ctrl+Z', 'While a toast with Undo shows'),
  AppShortcut('Set Watching', '1', 'Library, in a row menu'),
  AppShortcut('Set Planned', '2', 'Library, in a row menu'),
  AppShortcut('Set Completed', '3', 'Library, in a row menu'),
  AppShortcut('Set On hold', '4', 'Library, in a row menu'),
  AppShortcut(
    'Add an episode',
    '+',
    'Library, in a row menu of a watched title',
  ),
  AppShortcut('Close a menu or popover', 'Esc', 'Anywhere one is open'),
];

/// Binds the app-wide shortcuts around [child]. A text field lower in the tree
/// handles its own keys first, so Ctrl+Z still undoes typing there.
class AppShortcuts extends ConsumerWidget {
  const AppShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            ref.read(toastHostProvider.notifier).undoNewest(),
      },
      // something always holds focus, so the keys are heard on a bare page
      child: Focus(autofocus: true, skipTraversal: true, child: child),
    );
  }
}
