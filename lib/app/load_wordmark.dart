import 'dart:async';

import 'package:flutter/widgets.dart';

import '../components/app_popover.dart';
import '../components/flap.dart';
import '../components/floating_panel.dart';
import '../components/lamp.dart';
import '../components/pressable.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../library/count_format.dart';
import '../shell/window_config.dart';
import 'load_progress.dart';

enum _Side { word, count, allLoaded }

// the title bar's middle shade, so a turning half looks cut from the bar
final _plate = Color.lerp(Tokens.barTop, Tokens.barBottom, 0.5)!;

/// The Konsou wordmark. While the background work loads, it flaps over to the
/// count and back, taking turns until everything is in; then "All loaded" for
/// a moment, and Konsou again. A click while it loads lists each job.
class LoadWordmark extends StatefulWidget {
  const LoadWordmark({
    super.key,
    required this.progress,
    required this.updates,
  });

  /// What is loading when the wordmark is first drawn.
  final LoadProgress progress;
  final Stream<LoadProgress> updates;

  @override
  State<LoadWordmark> createState() => _LoadWordmarkState();
}

class _LoadWordmarkState extends State<LoadWordmark> {
  late final ValueNotifier<LoadProgress> _progress;
  StreamSubscription<LoadProgress>? _listening;
  var _side = _Side.word;
  Timer? _turn;

  @override
  void initState() {
    super.initState();
    _progress = ValueNotifier(widget.progress);
    if (widget.progress.job != null) _turnTo(_Side.count);
    _listening = widget.updates.listen(_showProgress);
  }

  void _showProgress(LoadProgress now) {
    final wasLoading = _progress.value.job != null;
    _progress.value = now;
    if (now.job != null) {
      if (!wasLoading) _turnTo(_Side.count);
      setState(() {});
    } else if (now.finished) {
      _turn?.cancel();
      setState(() => _side = _Side.allLoaded);
      _turn = Timer(Tokens.allLoadedHold, () {
        if (mounted && _progress.value.job == null) {
          setState(() => _side = _Side.word);
        }
      });
    } else {
      _turn?.cancel();
      setState(() => _side = _Side.word);
    }
  }

  // takes turns between the count and the word for as long as a job runs
  void _turnTo(_Side side) {
    _turn?.cancel();
    _side = side;
    _turn = Timer(
      side == _Side.count ? Tokens.countTurn : Tokens.wordmarkTurn,
      () {
        if (!mounted || _progress.value.job == null) return;
        setState(
          () => _turnTo(_side == _Side.count ? _Side.word : _Side.count),
        );
      },
    );
  }

  @override
  void dispose() {
    _turn?.cancel();
    _listening?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress.value;
    final face = switch (_side) {
      _Side.word => Text(WindowConfig.title, style: AppText.heading),
      _Side.allLoaded => Text('All loaded', style: AppText.heading),
      _Side.count => _LoadCount(progress),
    };
    final faceKey = _side == _Side.count
        ? (progress.job, progress.waiting)
        : _side;
    final listable = progress.job != null || _side == _Side.allLoaded;
    return AppPopover(
      gap: Tokens.space1,
      builder: (context, handle) => Pressable(
        label: listable ? _sentence(progress) : null,
        onPressed: listable ? handle.open : null,
        cursor: listable ? SystemMouseCursors.click : MouseCursor.defer,
        builder: (context, _) =>
            Flap(face: faceKey, plate: _plate, child: face),
      ),
      popoverBuilder: (context, handle) => ValueListenableBuilder(
        valueListenable: _progress,
        builder: (context, progress, _) => _LoadList(progress),
      ),
    );
  }
}

/// The count on the wordmark: each digit flaps on its own as it changes. While
/// the gate waits it goes plain ink with a pause mark, so the wait does not
/// read by color alone.
class _LoadCount extends StatelessWidget {
  const _LoadCount(this.progress);

  final LoadProgress progress;

  @override
  Widget build(BuildContext context) {
    final count = progress.current ?? (done: 0, total: 0);
    final digits = formatCount(count.done);
    final style = progress.waiting
        ? AppText.tally(Tokens.ink)
        : AppText.led(Tokens.pop);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progress.waiting) Text('‖ ', style: style),
        for (var i = 0; i < digits.length; i++)
          Flap(
            // counted from the right, so a new leading digit leaves the rest
            key: ValueKey(digits.length - i),
            face: digits[i],
            plate: _plate,
            duration: Tokens.motionFlapTick,
            child: Text(digits[i], style: style),
          ),
        Text(
          ' / ${formatCount(count.total)}',
          style: AppText.tally(Tokens.inkMuted),
        ),
      ],
    );
  }
}

class _LoadList extends StatelessWidget {
  const _LoadList(this.progress);

  final LoadProgress progress;

  @override
  Widget build(BuildContext context) {
    final finished = progress.job == null;
    return FloatingPanel(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space3),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                finished ? 'All loaded' : 'Loading your library',
                style: AppText.label(Tokens.ink, bold: true),
              ),
              const SizedBox(height: Tokens.space2),
              _row('Details', progress.details, LoadJob.details, finished),
              const SizedBox(height: Tokens.space2),
              _row('Covers', progress.covers, LoadJob.covers, finished),
              const SizedBox(height: Tokens.space2),
              Text(
                _sentence(progress),
                style: AppText.caption(Tokens.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String name, LoadCount count, LoadJob job, bool finished) {
    final active = progress.job == job;
    final done = finished || (count.total > 0 && count.done >= count.total);
    final lit = active && !progress.waiting;
    return Row(
      children: [
        Lamp(
          lit: done ? Tokens.ink : (lit ? Tokens.pop : null),
          waiting: active && progress.waiting,
        ),
        const SizedBox(width: Tokens.space2),
        Expanded(child: Text(name, style: AppText.label(Tokens.inkSoft))),
        const SizedBox(width: Tokens.space4),
        Text(
          finished
              ? 'Done'
              : '${formatCount(count.done)} / ${formatCount(count.total)}',
          style: AppText.tally(lit ? Tokens.pop : Tokens.ink),
        ),
      ],
    );
  }
}

String _sentence(LoadProgress progress) {
  final count = progress.current;
  if (count == null) return 'Every title has its details and cover.';
  if (progress.waiting) {
    return progress.job == LoadJob.details
        ? 'MAL is not answering. Trying again on its own.'
        : 'The picture server is not answering. Trying again on its own.';
  }
  final what = progress.job == LoadJob.details ? 'details' : 'covers';
  return 'Loading $what: ${formatCount(count.done)} of '
      '${formatCount(count.total)}.';
}
