import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/detail_providers.dart';
import '../../app/entry_actions.dart';
import '../../app/library_providers.dart';
import '../../components/app_button.dart';
import '../../components/app_menu.dart';
import '../../components/date_field.dart';
import '../../components/hold_row.dart';
import '../../components/notes_field.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_entry.dart';
import '../../library/entry_status.dart';
import 'detail_block.dart';

/// The user's own record of a title on the list, at the foot of the Detail
/// page on a filled plate: notes beside the start date and finished watches,
/// then the ways to restart, relink or remove it. The status, progress and
/// score are at the top.
class YourEntrySection extends ConsumerStatefulWidget {
  const YourEntrySection({
    super.key,
    required this.entry,
    required this.onUnlinked,
  });

  final TitleEntry entry;

  /// "Wrong title" took the entry off this page: show its page picker.
  final VoidCallback onUnlinked;

  @override
  ConsumerState<YourEntrySection> createState() => _YourEntrySectionState();
}

class _YourEntrySectionState extends ConsumerState<YourEntrySection> {
  final _notes = GlobalKey<NotesFieldState>();

  // read once: the notes are saved after the page has gone, when ref is not
  late final _edits = ref.read(entryEditsProvider);

  String get _id => widget.entry.entryId;

  Future<void> _remove() async {
    // typed notes are saved before the entry goes, not after
    _notes.currentState?.flush();
    await ref.read(entryActionsProvider).remove([_id]);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    EntryActions actions() => ref.read(entryActionsProvider);
    final linking = ref.watch(pageLinkingProvider);
    final started = entry.startedAt;
    final notes = DetailBlock(
      title: 'Notes',
      last: true,
      child: NotesField(
        key: _notes,
        initial: entry.notes ?? '',
        placeholder: 'Anything you want to remember about it',
        fill: Tokens.ground,
        onSave: (text) => _edits.setNotes(_id, text),
      ),
    );
    final dates = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailBlock(
          title: 'Started',
          child: Align(
            alignment: Alignment.centerLeft,
            child: DateField(
              value: started == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(started),
              latest: DateTime.now(),
              fill: Tokens.ground,
              onChanged: (date) => _edits.setStartedDate(_id, date),
            ),
          ),
        ),
        DetailBlock(
          title: 'Finished watches',
          last: true,
          child: _FinishedWatches(entry.finishedWatches),
        ),
      ],
    );
    final buttons = [
      if (entry.status == EntryStatus.completed)
        AppButton(
          label: 'Rewatch',
          kind: ButtonKind.secondary,
          onPressed: () => actions().rewatch(_id),
        ),
      if (!entry.isNotLinked)
        AppButton(
          label: 'Wrong title',
          kind: ButtonKind.secondary,
          onPressed: linking == null
              ? null
              : () => linking.replaceWrongTitle(
                  _id,
                  onUnlinked: widget.onUnlinked,
                ),
        ),
    ];
    final remove = SizedBox(
      width: Tokens.findFieldWidth + 2 * Tokens.space3,
      child: HoldRow(
        label: holdToRemoveLabel,
        holdTime: AppMenu.holdTime,
        hint: holdToRemoveHint,
        onDone: _remove,
      ),
    );
    // a filled plate, so the place to edit reads apart from the reading
    return Padding(
      padding: const EdgeInsets.only(bottom: DetailSection.gap),
      child: ColoredBox(
        color: Tokens.surface,
        child: Padding(
          padding: const EdgeInsets.all(Tokens.space5),
          child: DetailSection(
            title: 'Your entry',
            aside: const SectionNote('Saved as you type'),
            rule: Tokens.ground,
            last: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= Tokens.detailTextWidth;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: notes),
                          const SizedBox(width: Tokens.space5 + Tokens.space4),
                          Expanded(flex: 2, child: dates),
                        ],
                      )
                    else ...[
                      notes,
                      const SizedBox(height: Tokens.space5),
                      dates,
                    ],
                    const SizedBox(height: Tokens.space5),
                    // the ways out of the entry, apart from the fields
                    const ColoredBox(
                      color: Tokens.ground,
                      child: SizedBox(height: 1),
                    ),
                    const SizedBox(height: Tokens.space4),
                    if (wide)
                      Row(
                        children: [
                          for (final button in buttons) ...[
                            button,
                            const SizedBox(width: Tokens.space2),
                          ],
                          const Spacer(),
                          remove,
                        ],
                      )
                    else
                      Wrap(
                        spacing: Tokens.space2,
                        runSpacing: Tokens.space3,
                        children: [...buttons, remove],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FinishedWatches extends StatelessWidget {
  const _FinishedWatches(this.watches);

  final List<FinishedWatch> watches;

  @override
  Widget build(BuildContext context) {
    if (watches.isEmpty) {
      return Text('None yet', style: AppText.paragraph(Tokens.inkMuted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final watch in watches)
          Text(
            [
              watch.watchNumber == 0
                  ? 'First watch'
                  : 'Rewatch ${watch.watchNumber}',
              formatDate(
                DateTime.fromMillisecondsSinceEpoch(watch.completedAt),
              ),
              if (watch.isEstimated) 'date estimated',
            ].join(' · '),
            style: AppText.paragraph(Tokens.ink),
          ),
      ],
    );
  }
}
