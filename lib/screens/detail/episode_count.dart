import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../components/close_on_escape.dart';
import '../../components/field_text.dart';
import '../../components/icon_square_button.dart';
import '../../design/text_styles.dart';
import '../../design/tokens.dart';
import '../../icons/app_icons.dart';

/// "256 / 500" with a pencil after it. The pencil turns the watched number
/// into a field to type in. Enter, or a click anywhere else, sets it; Escape
/// leaves it as it was. The number is kept between 0 and [limit], which is the
/// episodes that have aired, asked when the number is set so it follows a
/// show that airs a new one; with no [limit] it is [total].
class EpisodeCount extends StatefulWidget {
  const EpisodeCount({
    super.key,
    required this.watched,
    required this.total,
    required this.onSet,
    this.limit,
  });

  final int watched;

  /// Null when MAL does not know the total.
  final int? total;
  final ValueChanged<int>? onSet;

  /// The most that can be set now, or null when there is no such limit.
  final ValueGetter<int?>? limit;

  static const fieldWidth = Tokens.space4 * 4;

  @override
  State<EpisodeCount> createState() => _EpisodeCountState();
}

class _EpisodeCountState extends State<EpisodeCount> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (_editing && !_focus.hasFocus) _commit();
  }

  void _start() {
    _controller.text = '${widget.watched}';
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    setState(() => _editing = true);
  }

  void _commit() {
    if (!_editing) return;
    setState(() => _editing = false);
    var count = int.tryParse(_controller.text);
    if (count == null) return;
    final total = widget.total;
    var most = widget.limit?.call();
    if (total != null && total > 0 && (most == null || most > total)) {
      most = total;
    }
    // past the limit it stops at the limit, but never moves down from where
    // the user already is
    if (most != null && count > most) {
      count = most > widget.watched ? most : widget.watched;
    }
    if (count != widget.watched) widget.onSet?.call(count);
  }

  void _cancel() {
    if (!_editing) return;
    setState(() => _editing = false);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.total;
    final known = total != null && total > 0;
    // LED digits, pop and glowing, in a sunk display
    final style = AppText.led(Tokens.pop);
    final ofTotal = Text(
      known ? ' / $total' : ' / ?',
      maxLines: 1,
      softWrap: false,
      style: style,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_editing)
          CloseOnEscape(
            onClose: _cancel,
            child: Container(
              width: EpisodeCount.fieldWidth,
              height: Tokens.controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
              decoration: BoxDecoration(
                color: Tokens.ground,
                border: Border.all(color: Tokens.pop, width: Tokens.focusRing),
              ),
              alignment: Alignment.centerRight,
              child: FieldText(
                controller: _controller,
                focusNode: _focus,
                placeholder: '',
                autofocus: true,
                // the digits go plain ink while typed: pop on the selection
                // slab is 2.3:1, ink on it 7.9:1
                style: AppText.tally(Tokens.ink),
                textAlign: TextAlign.end,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _commit(),
                onTapOutside: (_) => _focus.unfocus(),
              ),
            ),
          )
        else
          Container(
            key: const Key('episode-display'),
            height: Tokens.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: Tokens.space3),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Tokens.wellFill,
              borderRadius: Tokens.coverCorners,
              boxShadow: [
                BoxShadow(color: Tokens.edgeLight, offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.watched}',
                  maxLines: 1,
                  softWrap: false,
                  style: style,
                ),
                ofTotal,
              ],
            ),
          ),
        if (_editing) ofTotal,
        if (widget.onSet != null) ...[
          const SizedBox(width: Tokens.space1),
          IconSquareButton(
            icon: AppIcons.pencil,
            label: 'Edit the episode count',
            onPressed: _editing ? null : _start,
          ),
        ],
      ],
    );
  }
}
