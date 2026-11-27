import 'package:flutter/widgets.dart';

import '../library/entry_status.dart';
import '../library/row_labels.dart';
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
    this.loadingDetails = false,
    this.notLinked = false,
  });

  final CardCount count;
  final double? malScore;
  final bool narrow;
  final EntryStatus? status;
  final bool loadingDetails;
  final bool notLinked;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      EpisodeColumn(count: count, status: status),
      if (!narrow)
        MalColumn(score: malScore, loading: loadingDetails, blank: notLinked),
    ],
  );
}
