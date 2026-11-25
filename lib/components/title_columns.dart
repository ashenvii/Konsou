import 'package:flutter/widgets.dart';

import '../library/entry_status.dart';
import 'episode_column.dart';
import 'mal_column.dart';

/// The episode and MAL columns every row has. A [narrow] row has no room for
/// the MAL column; its score moves into the small line (`RowSmallLine`).
class TitleColumns extends StatelessWidget {
  const TitleColumns({
    super.key,
    required this.count,
    required this.malScore,
    required this.narrow,
    this.status,
    this.finished = true,
    this.showStatus = true,
    this.loadingDetails = false,
    this.notLinked = false,
  });

  final String count;
  final double? malScore;
  final bool narrow;
  final EntryStatus? status;
  final bool finished;
  final bool showStatus;
  final bool loadingDetails;
  final bool notLinked;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      EpisodeColumn(
        count: count,
        status: status,
        finished: finished,
        showStatus: showStatus,
        narrow: narrow,
      ),
      if (!narrow)
        MalColumn(score: malScore, loading: loadingDetails, blank: notLinked),
    ],
  );
}
