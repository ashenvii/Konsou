import 'package:flutter/widgets.dart';

import '../components/app_button.dart';
import '../design/tokens.dart';
import '../mal/request_gate.dart';
import '../net/request_timeout.dart';

/// Makes the app's real gates act up, MAL's API and the picture server
/// together, until set back to Normal or the app restarts.
class MalTroubleSection extends StatefulWidget {
  const MalTroubleSection({super.key});

  @override
  State<MalTroubleSection> createState() => _MalTroubleSectionState();
}

class _MalTroubleSectionState extends State<MalTroubleSection> {
  static const _labels = {
    MalTrouble.normal: 'Normal',
    MalTrouble.slow: 'Slow',
    MalTrouble.rateLimited: 'Rate limited',
    MalTrouble.offline: 'Offline',
  };

  @override
  Widget build(BuildContext context) {
    final current = RequestGate.trouble;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Tokens.space2,
          runSpacing: Tokens.space2,
          children: [
            for (final MapEntry(key: trouble, value: label) in _labels.entries)
              AppButton(
                label: label,
                kind: trouble == current
                    ? ButtonKind.primary
                    : ButtonKind.secondary,
                onPressed: () => setState(() => RequestGate.trouble = trouble),
              ),
          ],
        ),
        const SizedBox(height: Tokens.space2),
        Text(
          'Now: ${_labels[current]}. Slow never answers, so each request '
          'gives up after ${requestTimeout.inSeconds} s. Every request acts '
          'up, the background loading too, until it is back on Normal.',
          style: const TextStyle(
            fontFamily: Tokens.mono,
            fontSize: Tokens.text2,
            color: Tokens.inkMuted,
          ),
        ),
      ],
    );
  }
}
