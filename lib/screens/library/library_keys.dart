import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../library/entry_status.dart';
import '../../library/library_view.dart';
import 'edit_entry.dart';
import 'quick_panel.dart';
import 'row_marker.dart';
import 'status_keys.dart';

KeyEventResult handleLibraryKey(WidgetRef ref, KeyEvent event) {
  if (event is! KeyDownEvent) return KeyEventResult.ignored;
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext?.findAncestorWidgetOfExactType<EditableText>() != null) {
    return KeyEventResult.ignored;
  }
  final keys = HardwareKeyboard.instance;
  final key = event.logicalKey;

  final menuKey =
      key == LogicalKeyboardKey.contextMenu ||
      (key == LogicalKeyboardKey.f10 && keys.isShiftPressed);
  if (menuKey) {
    final marker = RowMarker.ofFocus();
    if (marker == null) return KeyEventResult.ignored;
    marker.openMenu();
    return KeyEventResult.handled;
  }

  if (keys.isControlPressed || keys.isAltPressed || keys.isMetaPressed) {
    return KeyEventResult.ignored;
  }
  // a letter jumps to its heading in the A to Z view
  final letter = key.keyLabel.length == 1 ? key.keyLabel.toUpperCase() : '';
  if (RegExp(r'^[A-Z]$').hasMatch(letter) &&
      ref.read(librarySortChoiceProvider).value == LibrarySort.title) {
    ref.read(libraryLetterJumpProvider.notifier).to(letter);
    return KeyEventResult.handled;
  }
  final status = _statusFor(key);
  final addEpisode =
      key == LogicalKeyboardKey.numpadAdd ||
      (key == LogicalKeyboardKey.equal && keys.isShiftPressed);
  if (status == null && !addEpisode) return KeyEventResult.ignored;

  final entryId =
      ref.read(libraryHoveredRowProvider) ?? RowMarker.ofFocus()?.entryId;
  if (entryId == null) return KeyEventResult.ignored;
  editEntry(
    ref.read,
    entryId,
    (actions) => status != null
        ? actions.setStatus(entryId, status)
        : actions.addEpisode(entryId),
  );
  return KeyEventResult.handled;
}

EntryStatus? _statusFor(LogicalKeyboardKey key) {
  final digit = digitKeys.indexOf(key);
  final index = digit >= 0 ? digit : numpadKeys.indexOf(key);
  return index < 0 ? null : QuickPanel.keyed[index];
}
