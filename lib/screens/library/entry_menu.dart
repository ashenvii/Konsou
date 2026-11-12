import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../components/app_menu.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';
import 'status_keys.dart';

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
    MenuEntry statusEntry(
      EntryStatus status, {
      String? key,
      bool dividerAbove = false,
    }) => MenuEntry(
      label: status.label,
      shortcut: key,
      selected: status == current,
      dividerAbove: dividerAbove,
      onPressed: () => _status(status),
    );
    // the same groups as the Library's status menu
    var firstAction = true;
    MenuEntry action(String label, VoidCallback onPressed, {String? key}) {
      final entry = MenuEntry(
        label: label,
        shortcut: key,
        dividerAbove: firstAction,
        onPressed: onPressed,
      );
      firstAction = false;
      return entry;
    }

    return CallbackShortcuts(
      bindings: {
        for (final (index, status) in EntryMenu.keyed.indexed) ...{
          SingleActivator(digitKeys[index]): () => _status(status),
          SingleActivator(numpadKeys[index]): () => _status(status),
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
              // a hairline before On hold
              statusEntry(
                status,
                key: '${index + 1}',
                dividerAbove: status == EntryStatus.onHold,
              ),
            statusEntry(EntryStatus.dropped),
            statusEntry(EntryStatus.notInterested),
            if (_watching)
              action('+ Episode', () => _run(widget.onAddEpisode), key: '+'),
            if (current == EntryStatus.completed)
              action('Rewatch', () => _run(widget.onRewatch)),
            action('Open details', () => _run(widget.onOpen)),
            MenuEntry(
              label: seasons > 1
                  ? 'Hold to remove all $seasons'
                  : 'Hold to remove',
              destructive: true,
              hold: true,
              dividerAbove: true,
              holdHint: 'Hold for a second. It cannot be undone.',
              onPressed: () => _run(widget.onRemove),
            ),
          ],
        ),
      ),
    );
  }
}
