import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/entry_actions.dart';
import '../../app/library_providers.dart';
import '../../components/status_menu_entries.dart';
import '../../detail/title_details.dart';
import '../../detail/title_entry.dart';
import '../../library/aired_episodes.dart';
import '../../library/earlier_titles.dart';
import 'entry_controls.dart';

/// The entry controls wired to the list: they edit [entry], or add the title
/// of [details] when there is no entry.
class LiveEntryControls extends ConsumerWidget {
  const LiveEntryControls({
    super.key,
    this.entry,
    this.details,
    this.statusOnly = false,
  }) : assert(entry != null || details != null);

  final TitleEntry? entry;
  final TitleDetails? details;
  final bool statusOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // read when used: the controls draw before any edit is asked for
    EntryActions actions() => ref.read(entryActionsProvider);
    final entry = this.entry;
    final details = this.details;
    if (entry == null) {
      return EntryControls(
        statusOnly: statusOnly,
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
    return EntryControls(
      statusOnly: statusOnly,
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
      // the same count the plus button is held to, taken when a number is set
      episodeLimit: details == null
          ? null
          : () => countAiredEpisodes(
              airingStatus: details.airingStatus,
              mediaType: details.mediaType,
              startDate: details.startDate,
              broadcastTime: details.broadcastTime,
              total: details.episodes,
              now: DateTime.now(),
            ),
    );
  }
}
