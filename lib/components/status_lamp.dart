import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../library/entry_status.dart';

/// A small round lamp for a title's status, the console's light. Watching (and
/// rewatching) is lit pop, a finished title is lit ink, everything else is off.
/// Never alone: the count or word beside it says the exact status.
class StatusLamp extends StatelessWidget {
  const StatusLamp(this.status, {super.key, this.finished = true});

  final EntryStatus status;

  /// Off for a Completed franchise with a season left, so it does not light.
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final lit = switch (status) {
      EntryStatus.watching || EntryStatus.rewatching => Tokens.pop,
      EntryStatus.completed when finished => Tokens.ink,
      _ => null,
    };
    return SizedBox.square(
      key: const Key('status-lamp'),
      dimension: Tokens.lampSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: lit ?? Tokens.lampOff,
          boxShadow: lit == null
              ? null
              : [
                  BoxShadow(
                    color: lit.withValues(alpha: 0.6),
                    blurRadius: Tokens.lampGlow,
                  ),
                ],
        ),
      ),
    );
  }
}
