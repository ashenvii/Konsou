import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../components/app_menu.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';

/// The menu of one Library row: set a status (keys 1 to 4 do the first four),
/// add an episode while watching, rewatch a finished title, open details and
/// remove. Removing asks in place first ("Are you sure?", or "Remove all 3?"
/// for a franchise). Every action runs and then calls [onClose].
class EntryMenu extends StatefulWidget {
  const EntryMenu({
    super.key,
    required this.row,
    required this.onStatus,
    required this.onAddEpisode,
    required this.onRewatch,
    required this.onOpen,
    required this.onRemove,
    required this.onClose,
  });

  final LibraryRow row;
  final ValueChanged<EntryStatus> onStatus;
  final VoidCallback onAddEpisode;
  final VoidCallback onRewatch;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final VoidCallback onClose;

  /// The statuses with a number key, in key order.
  static const keyed = [
    EntryStatus.watching,
    EntryStatus.planned,
    EntryStatus.completed,
    EntryStatus.onHold,
  ];

  @override
  State<EntryMenu> createState() => _EntryMenuState();
}

class _EntryMenuState extends State<EntryMenu> {
  var _confirming = false;

  bool get _watching => watchingStatuses.contains(widget.row.status);

  void _run(VoidCallback action) {
    action();
    widget.onClose();
  }

  void _status(EntryStatus status) => _run(() => widget.onStatus(status));

  @override
  Widget build(BuildContext context) {
    final current = EntryStatus.parse(widget.row.status);
    final seasons = widget.row.entryIds.length;
    MenuEntry statusEntry(EntryStatus status, {String? key}) => MenuEntry(
      label: status.label,
      shortcut: key,
      selected: status == current,
      onPressed: () => _status(status),
    );
    return CallbackShortcuts(
      bindings: {
        for (final (index, status) in EntryMenu.keyed.indexed) ...{
          SingleActivator(_digits[index]): () => _status(status),
          SingleActivator(_numpad[index]): () => _status(status),
        },
        if (_watching) ...{
          // the plus on the main row is shift and the equals key
          const SingleActivator(LogicalKeyboardKey.equal, shift: true): () =>
              _run(widget.onAddEpisode),
          const SingleActivator(LogicalKeyboardKey.numpadAdd): () =>
              _run(widget.onAddEpisode),
        },
      },
      child: Focus(
        autofocus: true,
        child: AppMenu(
          entries: [
            for (final (index, status) in EntryMenu.keyed.indexed)
              statusEntry(status, key: '${index + 1}'),
            statusEntry(EntryStatus.dropped),
            statusEntry(EntryStatus.notInterested),
            if (_watching)
              MenuEntry(
                label: '+ Episode',
                onPressed: () => _run(widget.onAddEpisode),
              ),
            if (current == EntryStatus.completed)
              MenuEntry(
                label: 'Rewatch',
                onPressed: () => _run(widget.onRewatch),
              ),
            MenuEntry(
              label: 'Open details',
              onPressed: () => _run(widget.onOpen),
            ),
            MenuEntry(
              label: !_confirming
                  ? 'Remove from list'
                  : (seasons > 1 ? 'Remove all $seasons?' : 'Are you sure?'),
              destructive: true,
              onPressed: _confirming
                  ? () => _run(widget.onRemove)
                  : () => setState(() => _confirming = true),
            ),
          ],
        ),
      ),
    );
  }
}

const _digits = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
];

const _numpad = [
  LogicalKeyboardKey.numpad1,
  LogicalKeyboardKey.numpad2,
  LogicalKeyboardKey.numpad3,
  LogicalKeyboardKey.numpad4,
];
