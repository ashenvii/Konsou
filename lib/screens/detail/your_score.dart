import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../app/toast_words.dart';
import '../../components/app_popover.dart';
import '../../components/floating_panel.dart';
import '../../components/pressable.dart';
import '../../components/star_rating.dart';
import '../../design/tokens.dart';
import '../../detail/title_entry.dart';
import 'score_figure.dart';

/// The user's own score beside MAL's, the same size. A click opens the ten
/// stars to set or clear it.
class YourScore extends ConsumerWidget {
  const YourScore({super.key, required this.entry});

  final TitleEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = entry.score;
    return AppPopover(
      gap: Tokens.space1,
      builder: (context, handle) => Pressable(
        label: 'Your score',
        onPressed: handle.open,
        builder: (context, state) => ScoreFigure(
          value: score?.toString(),
          empty: 'Rate',
          label: 'Your score',
          settable: true,
          lit: state.hovered || state.focused || handle.isOpen,
        ),
      ),
      popoverBuilder: (context, handle) => FloatingPanel(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.space3),
          child: StarRating(
            value: score,
            labelFor: rateStarLabel,
            clearLabel: clearRatingLabel,
            onChanged: (score) {
              ref.read(entryActionsProvider).rate(entry.entryId, score);
              handle.close();
            },
          ),
        ),
      ),
    );
  }
}
