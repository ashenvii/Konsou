import 'package:flutter/painting.dart';

import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../library/entry_status.dart';

/// An episode count's ink: the pop LED while watching, ink for any other
/// status, soft ink for a title not on your list ([status] null).
TextStyle chooseCountStyle(EntryStatus? status, {required double size}) =>
    switch (status) {
      null => AppText.tally(Tokens.inkSoft, size: size),
      EntryStatus.watching ||
      EntryStatus.rewatching => AppText.led(Tokens.pop, size: size),
      _ => AppText.tally(Tokens.ink, size: size),
    };
