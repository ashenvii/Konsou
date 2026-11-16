import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/entry_actions.dart';
import '../../app/library_providers.dart';
import '../../components/status_menu_entries.dart';
import '../../detail/title_details.dart';
import '../../detail/title_entry.dart';
import '../../library/earlier_titles.dart';
import 'entry_bar.dart';

/// The entry bar wired to the list: it edits [entry], or adds the title of
/// [details] when there is no entry.
class LiveEntryBar extends ConsumerWidget {
  const LiveEntryBar({super.key, this.entry, this.details})
    : assert(entry != null || details != null);

  final TitleEntry? entry;
  final TitleDetails? details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // read when used: the bar draws before any edit is asked for
    EntryActions actions() => ref.read(entryActionsProvider);
    final entry = this.entry;
    final details = this.details;
    if (entry == null) {
      return EntryBar(
        statusEntries: statusMenuEntries(
          onPick: (status) => actions().add(
            EarlierTitle(
              malId: details!.malId,
              name: details.name,
              isExtra: false,
              mediaType: details.mediaType,
              startDate: details.startDate,
              episodes: details.episodes,
            ),
            status,
            airing: details.airingStatus,
          ),
        ),
      );
    }
    final id = entry.entryId;
    final watched = entry.episodesWatched;
    return EntryBar(
      status: entry.status,
      watched: watched,
      total: details?.episodes,
      statusEntries: statusMenuEntries(
        current: entry.status,
        onPick: (status) => actions().setStatus(id, status),
      ),
      onMinus: watched > 0
          ? () => actions().setEpisodes(id, watched - 1)
          : null,
      onPlus: () => actions().addEpisode(id),
      onStep: (count) => actions().setEpisodes(id, count),
    );
  }
}
