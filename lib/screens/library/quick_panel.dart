import 'package:flutter/widgets.dart';

import '../../components/app_button.dart';
import '../../components/app_menu.dart';
import '../../components/floating_panel.dart';
import '../../components/hairline.dart';
import '../../components/hover_tip.dart';
import '../../components/pressable.dart';
import '../../components/raised_key.dart';
import '../../components/remove_key.dart';
import '../../components/status_mark.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/app_icon.dart';
import '../../library/entry_status.dart';
import '../../library/library_row.dart';
import 'status_keys.dart';

/// What right click (or the three dots, or the Menu key) opens on a Library
/// title, one height for every status: its details on top with the trash key
/// in the corner, then the four main statuses as icon keys with the current
/// one lit and its word under them, Dropped and Not interested as words
/// beside it, then Open details. Picking a status keeps the panel open, so
/// the change shows in it; Open details and a finished hold on the trash key
/// close it, as do Escape and a click outside. Episodes and Rewatch are on
/// Detail.
class QuickPanel extends StatelessWidget {
  const QuickPanel({
    super.key,
    required this.row,
    required this.details,
    required this.onStatus,
    required this.onOpen,
    required this.onRemove,
    required this.onClose,
  });

  final LibraryRow row;

  /// The title's details (`CardDetails`), with [cornerRoom] kept at the right
  /// of its first lines.
  final Widget details;
  final ValueChanged<EntryStatus> onStatus;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final VoidCallback onClose;

  /// The statuses with keys, which keys 1 to 4 also set while it is open.
  static const keyed = [
    EntryStatus.watching,
    EntryStatus.planned,
    EntryStatus.completed,
    EntryStatus.onHold,
  ];

  /// The rarer statuses, as words under the keys.
  static const worded = [EntryStatus.dropped, EntryStatus.notInterested];

  /// Room the details keep at their right for the trash key.
  static const cornerRoom = Tokens.controlHeight + Tokens.space3;

  void _closeAfter(VoidCallback action) {
    action();
    onClose();
  }

  String get _removeWords {
    final seasons = row.entryIds.length;
    return seasons > 1
        ? 'Hold to remove all $seasons seasons'
        : 'Hold to remove from your list';
  }

  @override
  Widget build(BuildContext context) {
    final current = row.status;
    // the trash key's face centred on the heading's first line
    final headingLine = _lineHeight(
      context,
      AppText.heading.copyWith(height: Tokens.lineHeightWrapped),
    );
    final cornerTop = (headingLine - Tokens.controlHeight) / 2 - keyLift.dy;
    return CallbackShortcuts(
      bindings: {
        for (final (index, status) in keyed.indexed) ...{
          SingleActivator(digitKeys[index]): () => onStatus(status),
          SingleActivator(numpadKeys[index]): () => onStatus(status),
        },
      },
      child: Focus(
        autofocus: true,
        child: FloatingPanel(
          child: SizedBox(
            width: Tokens.popoverWidth,
            // scrolls only in a window too short for it
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Tokens.space4),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        details,
                        Positioned(
                          top: cornerTop,
                          right: 0,
                          child: RemoveKey(
                            words: _removeWords,
                            holdTime: AppMenu.holdTime,
                            onDone: () => _closeAfter(onRemove),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Hairline(),
                  Padding(
                    padding: const EdgeInsets.all(Tokens.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            for (final (index, status) in keyed.indexed) ...[
                              if (index > 0)
                                const SizedBox(width: Tokens.space2),
                              Expanded(
                                child: _StatusPick(
                                  status,
                                  current: status == current,
                                  onPressed: () => onStatus(status),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: Tokens.space2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                current.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.caption(Tokens.ink),
                              ),
                            ),
                            const SizedBox(width: Tokens.space3),
                            // at a large text size the words wrap, never cut
                            Flexible(
                              flex: 2,
                              child: Wrap(
                                alignment: WrapAlignment.end,
                                spacing: Tokens.space3,
                                children: [
                                  for (final status in worded)
                                    _StatusPick(
                                      status,
                                      current: status == current,
                                      onPressed: () => onStatus(status),
                                      word: true,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Hairline(),
                  Padding(
                    padding: const EdgeInsets.all(Tokens.space4),
                    child: AppButton(
                      label: 'Open details',
                      kind: ButtonKind.secondary,
                      onPressed: () => _closeAfter(onOpen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _lineHeight(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }
}

/// A status to pick: an icon key, or with [word] a small word for the rarer
/// ones. The current one is lit in pop and does nothing. A key says its
/// status on a short hover.
class _StatusPick extends StatelessWidget {
  const _StatusPick(
    this.status, {
    required this.current,
    required this.onPressed,
    this.word = false,
  });

  final EntryStatus status;
  final bool current;
  final VoidCallback onPressed;
  final bool word;

  @override
  Widget build(BuildContext context) {
    final pick = Pressable(
      label: status.label,
      selected: current,
      onPressed: current ? () {} : onPressed,
      cursor: current ? SystemMouseCursors.basic : SystemMouseCursors.click,
      builder: (context, state) {
        if (word) {
          final ink = current
              ? Tokens.pop
              : (state.hovered ? Tokens.ink : Tokens.inkMuted);
          return Text(
            status.label,
            maxLines: 1,
            softWrap: false,
            style: AppText.caption(ink).copyWith(
              decoration: TextDecoration.underline,
              decorationColor: current ? Tokens.pop : Tokens.line,
            ),
          );
        }
        return RaisedKey(
          primary: current,
          lit: state.hovered && !current,
          sunk: state.pressed && !current,
          child: SizedBox(
            height: Tokens.controlHeight,
            child: Center(
              child: AppIcon(
                StatusMark.iconFor(status),
                size: Tokens.iconSize,
                color: current ? Tokens.onPop : Tokens.ink,
              ),
            ),
          ),
        );
      },
    );
    return word ? pick : HoverTip(label: status.label, child: pick);
  }
}
