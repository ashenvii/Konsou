import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../components/find_field.dart';
import '../../components/hover_delays_state.dart';
import '../../components/icon_square_button.dart';
import '../../components/motion.dart';
import '../../design/tokens.dart';
import '../../icons/app_icons.dart';

/// The Library's Find field, wired to the find choice.
class LibraryFind extends ConsumerStatefulWidget {
  const LibraryFind({super.key});

  @override
  ConsumerState<LibraryFind> createState() => _LibraryFindState();
}

class _LibraryFindState extends ConsumerState<LibraryFind>
    with HoverDelaysState<LibraryFind> {
  LibraryFindChoice get _choice => ref.read(libraryFindChoiceProvider.notifier);

  @override
  void hoverOpen() => _choice.open();

  // typed text keeps it open
  @override
  void hoverClose() {
    if ((ref.read(libraryFindChoiceProvider) ?? '').isEmpty) _choice.close();
  }

  // the field stays drawn while it slides shut, then the magnifier comes back
  var _fieldShown = false;

  @override
  Widget build(BuildContext context) {
    final find = ref.watch(libraryFindChoiceProvider);
    final open = find != null;
    if (open) _fieldShown = true;
    return MouseRegion(
      onEnter: (_) => hoverDelays.entered(isOpen: open),
      // only an empty field closes when the pointer leaves
      onExit: (_) => hoverDelays.left(
        isOpen: ref.read(libraryFindChoiceProvider)?.isEmpty ?? false,
      ),
      child: AnimatedContainer(
        duration: chooseMotionDuration(context, Tokens.motionSlide),
        curve: Curves.easeOut,
        width: open ? Tokens.findFieldWidth : Tokens.controlHeight,
        height: Tokens.controlHeight,
        onEnd: () {
          if (!open && _fieldShown) setState(() => _fieldShown = false);
        },
        child: _fieldShown
            ? ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerRight,
                  minWidth: Tokens.findFieldWidth,
                  maxWidth: Tokens.findFieldWidth,
                  child: FindField(
                    initial: find ?? '',
                    placeholder: 'Search your library',
                    onChanged: _choice.change,
                    onClose: _choice.close,
                  ),
                ),
              )
            : IconSquareButton(
                icon: AppIcons.search,
                label: 'Find',
                onPressed: _choice.open,
              ),
      ),
    );
  }
}
