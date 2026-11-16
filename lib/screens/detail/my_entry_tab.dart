import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/detail_providers.dart';
import '../../app/entry_actions.dart';
import '../../app/library_providers.dart';
import '../../app/toast_words.dart';
import '../../components/app_button.dart';
import '../../components/app_menu.dart';
import '../../components/date_field.dart';
import '../../components/hold_row.dart';
import '../../components/notes_field.dart';
import '../../components/star_rating.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../detail/title_entry.dart';
import '../../library/entry_status.dart';
import 'detail_block.dart';

/// The My entry tab: the user's own rating, notes, dates and finished watches
/// for a title on the list, and the ways to restart, relink or remove it.
class MyEntryTab extends ConsumerStatefulWidget {
  const MyEntryTab({super.key, required this.entry, required this.onUnlinked});

  final TitleEntry entry;

  /// "Wrong title" took the entry off this page: show its page picker.
  final VoidCallback onUnlinked;

  @override
  ConsumerState<MyEntryTab> createState() => _MyEntryTabState();
}

class _MyEntryTabState extends ConsumerState<MyEntryTab> {
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
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Tokens.detailTextWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailBlock(
              title: 'Your rating',
              child: StarRating(
                value: entry.score,
                labelFor: rateStarLabel,
                clearLabel: clearRatingLabel,
                onChanged: (score) => actions().rate(_id, score),
              ),
            ),
            DetailBlock(
              title: 'Notes',
              child: NotesField(
                key: _notes,
                initial: entry.notes ?? '',
                placeholder: 'Anything you want to remember about it',
                onSave: (text) => _edits.setNotes(_id, text),
              ),
            ),
            DetailBlock(
              title: 'Started',
              child: DateField(
                value: started == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(started),
                latest: DateTime.now(),
                onChanged: (date) => _edits.setStartedDate(_id, date),
              ),
            ),
            DetailBlock(
              title: 'Finished watches',
              child: _FinishedWatches(entry.finishedWatches),
            ),
            Row(
              children: [
                if (entry.status == EntryStatus.completed) ...[
                  AppButton(
                    label: 'Rewatch',
                    kind: ButtonKind.secondary,
                    onPressed: () => actions().rewatch(_id),
                  ),
                  const SizedBox(width: Tokens.space2),
                ],
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
              ],
            ),
            const SizedBox(height: Tokens.space4),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: Tokens.findFieldWidth + 2 * Tokens.space3,
                child: HoldRow(
                  label: holdToRemoveLabel,
                  holdTime: AppMenu.holdTime,
                  hint: holdToRemoveHint,
                  onDone: _remove,
                ),
              ),
            ),
          ],
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
