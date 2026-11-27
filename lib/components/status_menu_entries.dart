import 'package:flutter/foundation.dart' show ValueChanged;

import '../library/entry_status.dart';
import 'app_menu.dart';

/// Every status a title on the list can take, in the menu's order.
const menuStatuses = [
  EntryStatus.watching,
  EntryStatus.planned,
  EntryStatus.completed,
  EntryStatus.onHold,
  EntryStatus.dropped,
  EntryStatus.notInterested,
];

/// The status rows of the Library's menu, in its order and groups. A locked
/// status stays in the list; picking it explains why. Each of [keyed] shows
/// its place in that list as its key.
List<MenuEntry> statusMenuEntries({
  EntryStatus? current,
  required ValueChanged<EntryStatus> onPick,
  List<EntryStatus> keyed = const [],
}) => [
  for (final status in menuStatuses)
    MenuEntry(
      label: status.label,
      shortcut: keyed.contains(status) ? '${keyed.indexOf(status) + 1}' : null,
      selected: status == current,
      dividerAbove: status == EntryStatus.onHold,
      onPressed: () => onPick(status),
    ),
];
