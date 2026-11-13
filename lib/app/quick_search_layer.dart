import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/app_button.dart';
import '../components/app_checkbox.dart';
import '../components/close_on_escape.dart';
import '../components/cover_image.dart';
import '../components/floating_panel.dart';
import '../components/hairline.dart';
import '../components/hover_mark.dart';
import '../components/key_cap.dart';
import '../components/skeleton.dart';
import '../components/smooth_scroll.dart';
import '../components/status_mark.dart';
import '../components/sweep_button.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../library/quick_search.dart';
import 'cover_view.dart';
import 'quick_search_providers.dart';

/// Quick search: the page dimmed, and the popover dropped under the search
/// well. It opens from the well or Ctrl K.
class QuickSearchLayer extends ConsumerStatefulWidget {
  const QuickSearchLayer({super.key, this.onBrowse});

  /// Browse all: leave the search for Discover.
  final VoidCallback? onBrowse;

  @override
  ConsumerState<QuickSearchLayer> createState() => _QuickSearchLayerState();
}

class _QuickSearchLayerState extends ConsumerState<QuickSearchLayer> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _scroll = SmoothScrollController();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final search = ref.read(quickSearchProvider.notifier);
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      search.moveFocus(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      search.moveFocus(-1);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      search.activate();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(quickSearchProvider.select((state) => state.open), (_, open) {
      if (!open) return;
      _text.clear();
      _focus.requestFocus();
    });
    final state = ref.watch(quickSearchProvider);
    if (!state.open) return const SizedBox.shrink();
    final search = ref.read(quickSearchProvider.notifier);
    return CloseOnEscape(
      onClose: search.close,
      child: Focus(
        onKeyEvent: _key,
        child: Stack(
          children: [
            // dims everything under the bar; a click on it closes the search
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: search.close,
                child: ColoredBox(
                  color: Tokens.wellEdge.withValues(alpha: 0.78),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: LayoutBuilder(
                builder: (context, box) => Padding(
                  padding: const EdgeInsets.only(top: Tokens.space2),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Tokens.quickPanelWidth,
                      maxHeight: (box.maxHeight - Tokens.space5).clamp(
                        0,
                        Tokens.quickPanelMaxHeight,
                      ),
                    ),
                    child: FloatingPanel(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Field(
                            controller: _text,
                            focus: _focus,
                            onChanged: search.setQuery,
                          ),
                          Flexible(
                            child: SingleChildScrollView(
                              controller: _scroll,
                              child: _Results(state: state, search: search),
                            ),
                          ),
                          _Footer(
                            onBrowse: () {
                              search.close();
                              widget.onBrowse?.call();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sunk field at the top.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.focus,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = AppText.label(Tokens.ink).copyWith(fontSize: Tokens.text4);
    return ColoredBox(
      color: Tokens.ground,
      child: SizedBox(
        height: Tokens.quickFieldHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space4),
          child: Row(
            children: [
              const AppIcon(
                AppIcons.search,
                size: Tokens.iconSize,
                color: Tokens.inkMuted,
              ),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => controller.text.isEmpty
                          ? Text(
                              'Type a title',
                              style: style.copyWith(color: Tokens.inkMuted),
                            )
                          : const SizedBox.shrink(),
                    ),
                    EditableText(
                      controller: controller,
                      focusNode: focus,
                      autofocus: true,
                      style: style,
                      cursorColor: Tokens.ink,
                      backgroundCursorColor: Tokens.inkMuted,
                      selectionColor: Tokens.inkMuted,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Tokens.space3),
              const KeyCaps('Esc'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state, required this.search});

  final QuickState state;
  final QuickSearch search;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    var index = 0;
    Widget rowFor(QuickRow row) {
      final at = index++;
      return _ResultRow(
        row: row,
        focused: at == state.focus,
        onFocus: () => search.focusRow(at),
        onOpen: () => search.openRow(row),
        onTick: () => search.toggleComplete(row),
      );
    }

    if (!state.typing) {
      children.add(const _GroupLabel('Recent'));
      if (state.recent.isEmpty) {
        children.add(
          const _Note('Type a title to search your list and all anime.'),
        );
      }
      children.addAll(state.recent.map(rowFor));
    } else {
      final mine = state.shownMine;
      final online = state.shownOnline;
      if (mine.isNotEmpty) {
        children.add(const _GroupLabel('Your list'));
        children.addAll(mine.map(rowFor));
      }
      if (online.isNotEmpty || state.searching) {
        children.add(const _GroupLabel('All anime'));
        children.addAll(online.map(rowFor));
        if (state.searching) {
          children.addAll(
            List.generate(
              online.isEmpty ? quickFirst : 3,
              (_) => const _SkeletonRow(),
            ),
          );
        }
      }
      if (mine.isEmpty && online.isEmpty && !state.searching) {
        children.add(
          _Note(
            state.failed
                ? 'The online search could not be reached.'
                : 'No titles match "${state.query}".',
          ),
        );
      } else if (state.failed && !state.searching) {
        children.add(const _Note('The online search could not be reached.'));
      }
      if (state.hasMore) {
        children.add(
          _LoadMore(
            label: '$quickPage more',
            focused: state.focus == state.rows.length,
            onFocus: () => search.focusRow(state.rows.length),
            onTap: search.loadMore,
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Tokens.space4,
        Tokens.space4,
        Tokens.space4,
        Tokens.space1,
      ),
      child: Row(
        children: [
          Text(text, style: AppText.caption(Tokens.inkMuted)),
          const SizedBox(width: Tokens.space3),
          const Expanded(child: Hairline()),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Tokens.space4),
      child: Text(text, style: AppText.paragraph(Tokens.inkSoft)),
    );
  }
}

/// Moving through the rows with the keys keeps the highlighted one in view,
/// scrolling only as far as it takes. The pointer never scrolls: the row
/// under it is in view already, and a list that moves under a still pointer
/// puts the next row under it, which would scroll again, all the way down.
mixin _KeepsInView<T extends StatefulWidget> on State<T> {
  var _pointed = false;

  void point({required bool focused, required VoidCallback onFocus}) {
    if (focused) return;
    _pointed = true;
    onFocus();
  }

  void keepInView({required bool now, required bool was}) {
    final pointed = _pointed;
    _pointed = false;
    if (!now || was || pointed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final edge in const [
        ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ]) {
        Scrollable.ensureVisible(context, alignmentPolicy: edge);
      }
    });
  }
}

class _ResultRow extends StatefulWidget {
  const _ResultRow({
    required this.row,
    required this.focused,
    required this.onFocus,
    required this.onOpen,
    required this.onTick,
  });

  final QuickRow row;
  final bool focused;
  final VoidCallback onFocus;
  final VoidCallback onOpen;
  final VoidCallback onTick;

  @override
  State<_ResultRow> createState() => _ResultRowState();
}

class _ResultRowState extends State<_ResultRow> with _KeepsInView<_ResultRow> {
  @override
  void didUpdateWidget(_ResultRow old) {
    super.didUpdateWidget(old);
    keepInView(now: widget.focused, was: old.focused);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final focused = widget.focused;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (_) => point(focused: widget.focused, onFocus: widget.onFocus),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: focused
                ? const Border(
                    left: BorderSide(
                      color: Tokens.inkSoft,
                      width: Tokens.hoverEdge,
                    ),
                  )
                : null,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: focused ? Tokens.surface : null),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Tokens.space4,
                vertical: Tokens.space1,
              ),
              child: Row(
                children: [
                  AppCheckbox(
                    value: row.completed
                        ? CheckValue.checked
                        : CheckValue.empty,
                    onChanged: (_) => widget.onTick(),
                  ),
                  const SizedBox(width: Tokens.space3),
                  CoverView(malId: row.malId, width: Tokens.quickCoverWidth),
                  const SizedBox(width: Tokens.space3),
                  Expanded(child: _NameAndLine(row)),
                  if (row.status != null && !row.completed) ...[
                    const SizedBox(width: Tokens.space3),
                    StatusMark(
                      row.status!,
                      color: Tokens.inkMuted,
                      green: false,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NameAndLine extends StatelessWidget {
  const _NameAndLine(this.row);

  final QuickRow row;

  @override
  Widget build(BuildContext context) {
    final nameInk = row.onList ? Tokens.ink : Tokens.inkSoft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.name,
          style: AppText.label(nameInk),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Tokens.space1),
        Text(
          row.line,
          style: AppText.caption(Tokens.inkMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// A row of the same shape while a search runs, so nothing pops in.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Tokens.space4,
        vertical: Tokens.space1,
      ),
      child: Row(
        children: [
          SizedBox(width: Tokens.checkboxSize, height: Tokens.checkboxSize),
          SizedBox(width: Tokens.space3),
          CoverImage(width: Tokens.quickCoverWidth, loading: true),
          SizedBox(width: Tokens.space3),
          Expanded(child: SkeletonLines(title: 0.6, line: 0.3)),
        ],
      ),
    );
  }
}

/// Load more: a hairline with the count in it, not a button.
class _LoadMore extends StatefulWidget {
  const _LoadMore({
    required this.label,
    required this.focused,
    required this.onFocus,
    required this.onTap,
  });

  final String label;
  final bool focused;
  final VoidCallback onFocus;
  final VoidCallback onTap;

  @override
  State<_LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends State<_LoadMore> with _KeepsInView<_LoadMore> {
  bool _hovered = false;

  @override
  void didUpdateWidget(_LoadMore old) {
    super.didUpdateWidget(old);
    keepInView(now: widget.focused, was: old.focused);
  }

  @override
  Widget build(BuildContext context) {
    final lit = widget.focused || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      onHover: (_) => point(focused: widget.focused, onFocus: widget.onFocus),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: HoverMark(
          on: lit,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.space4,
              vertical: Tokens.space3,
            ),
            child: Row(
              children: [
                const Expanded(child: Hairline()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.space3,
                  ),
                  child: Text(
                    widget.label,
                    style: AppText.label(lit ? Tokens.ink : Tokens.inkSoft),
                  ),
                ),
                const Expanded(child: Hairline()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    Widget hint(List<String> keys, String words) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final key in keys) ...[
          KeyCaps(key),
          const SizedBox(width: Tokens.space1),
        ],
        const SizedBox(width: Tokens.space1),
        Text(words, style: AppText.caption(Tokens.inkMuted)),
      ],
    );
    return ColoredBox(
      color: Tokens.ground,
      child: SizedBox(
        height: Tokens.quickFooterHeight,
        child: Padding(
          padding: const EdgeInsets.only(
            left: Tokens.space4,
            right: Tokens.space3,
          ),
          child: Row(
            children: [
              hint(const ['↑', '↓'], 'Move'),
              const SizedBox(width: Tokens.space4),
              hint(const ['Enter'], 'Open'),
              const Spacer(),
              // search by screenshot is not built yet, so this does nothing
              SweepButton(label: 'Screenshot', onPressed: () {}),
              const SizedBox(width: Tokens.space2),
              AppButton(label: 'Browse all', onPressed: onBrowse),
            ],
          ),
        ),
      ),
    );
  }
}
