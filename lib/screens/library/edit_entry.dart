import 'package:flutter_riverpod/misc.dart';

import '../../app/entry_actions.dart';
import '../../app/library_providers.dart';

/// Runs [action] on an entry. With [keepInView] the row stays where it is,
/// showing its new status, until the tab changes.
Future<void> editEntry(
  T Function<T>(ProviderListenable<T> provider) read,
  String entryId,
  Future<Object?> Function(EntryActions actions) action, {
  bool keepInView = true,
}) async {
  // kept before the edit, so the reload the edit starts never drops the row
  if (keepInView) read(libraryKeptProvider.notifier).keep(entryId);
  await action(read(entryActionsProvider));
}
