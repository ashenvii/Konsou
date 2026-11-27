import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Asks MAL for a title's details while [child] is on screen and its MAL
/// score is [pending]: a title saved before the score was asked for. Nothing
/// asks for these in the background, so a list fills in where it is looked at;
/// a card scrolled away lets its request go.
class ScoreFill extends ConsumerWidget {
  const ScoreFill({
    super.key,
    required this.malId,
    required this.pending,
    required this.child,
    this.lane = Lane.screen,
  });

  final int? malId;
  final bool pending;
  final Widget child;
  final Lane lane;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = malId;
    if (pending && id != null) {
      ref.watch(detailOnScreenProvider(id, lane: lane));
    }
    return child;
  }
}
