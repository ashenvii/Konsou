import 'package:flutter/widgets.dart';

import '../components/app_button.dart';
import '../components/app_menu.dart';
import '../components/app_popover.dart';
import '../components/hover_tip.dart';
import '../components/icon_square_button.dart';
import '../components/panel.dart';
import '../components/presence.dart';
import '../components/toast_view.dart';
import '../design/text_styles.dart';
import '../design/tokens.dart';
import '../icons/app_icons.dart';

/// Things appearing and going, live: a menu, a tip and a toast.
class MotionSection extends StatefulWidget {
  const MotionSection({super.key});

  @override
  State<MotionSection> createState() => _MotionSectionState();
}

class _MotionSectionState extends State<MotionSection> {
  var _toast = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          child: Wrap(
            spacing: Tokens.space5,
            runSpacing: Tokens.space3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppPopover(
                builder: (context, handle) => AppButton(
                  label: 'Menu',
                  kind: ButtonKind.secondary,
                  opensMenu: true,
                  onPressed: handle.open,
                ),
                popoverBuilder: (context, handle) => AppMenu(
                  entries: [
                    MenuEntry(
                      label: 'Watching',
                      selected: true,
                      onPressed: handle.close,
                    ),
                    MenuEntry(label: 'Planned', onPressed: handle.close),
                    MenuEntry(label: 'Completed', onPressed: handle.close),
                  ],
                ),
              ),
              HoverTip(
                label: 'Marked as seen',
                child: IconSquareButton(
                  icon: AppIcons.search,
                  label: 'Tip',
                  onPressed: () {},
                ),
              ),
              AppButton(
                label: _toast ? 'Hide the toast' : 'Show the toast',
                kind: ButtonKind.secondary,
                onPressed: () => setState(() => _toast = !_toast),
              ),
            ],
          ),
        ),
        const SizedBox(height: Tokens.space3),
        SizedBox(
          height: Tokens.space5 * 3,
          child: Presence(
            visible: _toast,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ToastView(
                message: 'Marked as Completed',
                closeLabel: 'Close',
                onClose: () => setState(() => _toast = false),
              ),
            ),
          ),
        ),
        Text(
          'Menus and popovers fade in over 120 ms with a 4 px slide out of '
          'what opened them, down or up; '
          'they fade out over 80 ms. The toast and tips only fade. Ease-out '
          'on the way in, ease-in on the way out. A tip waits 400 ms, a menu '
          '60 ms. With reduced motion on, all of it is instant.',
          style: AppText.paragraph(Tokens.inkSoft),
        ),
      ],
    );
  }
}
