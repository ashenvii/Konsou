import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../icons/icon_def.dart';
import '../library/entry_status.dart';

/// The picture that tells a status apart. Completed is the one green mark; every
/// other status is an icon in ink, so colour stays rare.
class StatusMark extends StatelessWidget {
  const StatusMark(this.status, {super.key, this.color = Tokens.ink});

  final EntryStatus status;

  /// The ink for every status but Completed.
  final Color color;

  static IconDef iconFor(EntryStatus status) => switch (status) {
    EntryStatus.watching => AppIcons.watching,
    EntryStatus.planned => AppIcons.planned,
    EntryStatus.completed => AppIcons.check,
    EntryStatus.onHold => AppIcons.onHold,
    EntryStatus.dropped => AppIcons.dropped,
    EntryStatus.rewatching => AppIcons.rewatching,
    EntryStatus.notInterested => AppIcons.notInterested,
  };

  @override
  Widget build(BuildContext context) {
    return AppIcon(
      iconFor(status),
      size: Tokens.iconSize,
      color: status == EntryStatus.completed ? Tokens.mint : color,
    );
  }
}
