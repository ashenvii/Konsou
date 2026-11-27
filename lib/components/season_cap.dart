import 'package:flutter/widgets.dart';

import 'key_cap.dart';

/// The key cap in front of a franchise's count, "S2": the season the card
/// stands for, counted among the seasons on your list.
class SeasonCap extends StatelessWidget {
  const SeasonCap(this.season, {super.key});

  final int season;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Season $season',
    excludeSemantics: true,
    child: KeyCaps('S$season'),
  );
}
