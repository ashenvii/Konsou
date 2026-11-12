import 'package:flutter/widgets.dart';

import '../design/tokens.dart';
import 'countdown.dart';

class ToastTimer extends StatelessWidget {
  const ToastTimer({super.key, required this.countdown});

  final Countdown countdown;

  static const urgentBelow = 0.25;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Tokens.toastBarHeight,
      child: CountdownBuilder(
        countdown: countdown,
        builder: (context, share, running) {
          final color = !running
              ? Tokens.inkMuted
              : (share <= urgentBelow ? Tokens.amber : Tokens.inkSoft);
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: share,
              heightFactor: 1,
              child: ColoredBox(color: color),
            ),
          );
        },
      ),
    );
  }
}
