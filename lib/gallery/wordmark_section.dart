import 'dart:async';

import 'package:flutter/widgets.dart';

import '../app/load_progress.dart';
import '../app/load_wordmark.dart';
import '../components/app_button.dart';
import '../design/tokens.dart';
import '../mal/request_gate.dart';
import '../shell/app_shell.dart';

/// The wordmark on a strip of title bar, fed a made-up first import of 6,499
/// titles, so each moment can be seen without a real one.
class WordmarkSection extends StatefulWidget {
  const WordmarkSection({super.key});

  @override
  State<WordmarkSection> createState() => _WordmarkSectionState();
}

class _WordmarkSectionState extends State<WordmarkSection> {
  static const _total = 6499;
  final _updates = StreamController<LoadProgress>.broadcast();
  var _details = 1240;
  var _covers = 3810;
  LoadJob? _job;
  var _waiting = false;
  Timer? _tick;

  void _send(LoadProgress progress) => _updates.add(progress);

  void _run(LoadJob job, {bool waiting = false}) {
    _job = job;
    _waiting = waiting;
    _tick?.cancel();
    // at MAL's pace, one title each request gap, unless it is waiting
    if (!waiting) {
      _tick = Timer.periodic(requestGap, (_) {
        if (_job == LoadJob.details && _details < _total) _details++;
        if (_job == LoadJob.covers && _covers < _total) _covers++;
        _sendRunning();
      });
    }
    _sendRunning();
  }

  void _sendRunning() => _send(
    LoadProgress(
      job: _job,
      waiting: _waiting,
      details: (
        done: _job == LoadJob.covers ? _total : _details,
        total: _total,
      ),
      covers: (done: _covers, total: _total),
    ),
  );

  void _stop({required bool finished}) {
    _tick?.cancel();
    _job = null;
    _send(LoadProgress(finished: finished));
  }

  @override
  void dispose() {
    _tick?.cancel();
    _updates.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: titleBarFill,
          child: SizedBox(
            height: Tokens.barHeight,
            child: Padding(
              padding: const EdgeInsets.only(left: Tokens.space4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: LoadWordmark(
                  progress: const LoadProgress(),
                  updates: _updates.stream,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Tokens.space3),
        Wrap(
          spacing: Tokens.space2,
          runSpacing: Tokens.space2,
          children: [
            _button('Details start', () => _run(LoadJob.details)),
            _button('Covers start', () => _run(LoadJob.covers)),
            _button(
              'MAL stops answering',
              () => _run(LoadJob.details, waiting: true),
            ),
            _button('All loaded', () => _stop(finished: true)),
            _button('Nothing loading', () => _stop(finished: false)),
          ],
        ),
      ],
    );
  }

  Widget _button(String label, VoidCallback onPressed) =>
      AppButton(label: label, kind: ButtonKind.secondary, onPressed: onPressed);
}
