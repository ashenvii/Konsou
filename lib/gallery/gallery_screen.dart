import 'package:flutter/widgets.dart';

import '../components/app_button.dart';
import '../components/app_checkbox.dart';
import '../components/app_tab.dart';
import '../components/count_badge.dart';
import '../components/app_menu.dart';
import '../components/icon_square_button.dart';
import '../components/page_frame.dart';
import '../components/page_title.dart';
import '../components/panel.dart';
import '../components/status_mark.dart';
import 'library_rows_section.dart';
import '../library/entry_status.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../icons/score_star.dart';
import '../shell/app_rail.dart';

/// Every token and every component built so far, on one scrolling page. The
/// first screen in debug builds. Add a component here when it is built.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _tab = 0;
  CheckValue _plain = CheckValue.empty;
  CheckValue _filter = CheckValue.empty;

  @override
  Widget build(BuildContext context) {
    // SafeArea keeps the page clear of a phone's status bar. On desktop it
    // adds nothing.
    return SafeArea(
      child: SingleChildScrollView(
        padding: PageFrame.top.copyWith(bottom: Tokens.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageTitle('Gallery'),
            const _Note(
              'Every token and component built so far: the foundations, the '
              'controls, the parts a page is built from, then the icons. The '
              'mint scrollbar on the right is the one every page gets.',
            ),
            const _Section('Colors'),
            const _Colors(),
            const _Section('Type'),
            const _Type(),
            const _Section('Space'),
            const _Space(),
            const _Section('Sizes'),
            const _Sizes(),
            const _Section('Button'),
            Wrap(
              spacing: Tokens.space3,
              runSpacing: Tokens.space3,
              children: [
                AppButton(label: 'Primary', onPressed: () {}),
                AppButton(
                  label: 'Secondary',
                  kind: ButtonKind.secondary,
                  onPressed: () {},
                ),
                const AppButton(label: 'Disabled', onPressed: null),
                const AppButton(
                  label: 'Disabled secondary',
                  kind: ButtonKind.secondary,
                  onPressed: null,
                ),
              ],
            ),
            const _Section('Tab and count badge'),
            Wrap(
              children: [
                for (final (i, label) in [
                  'Browse',
                  'For you',
                  'Top 10',
                ].indexed)
                  AppTab(
                    label: label,
                    selected: _tab == i,
                    onPressed: () => setState(() => _tab = i),
                  ),
                AppTab(
                  label: 'Watching',
                  count: 5,
                  selected: _tab == 3,
                  onPressed: () => setState(() => _tab = 3),
                ),
              ],
            ),
            const SizedBox(height: Tokens.space3),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountBadge(5),
                SizedBox(width: Tokens.space3),
                CountBadge(42),
                SizedBox(width: Tokens.space3),
                CountBadge(250),
              ],
            ),
            const _Section('Checkbox'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppCheckbox(value: CheckValue.empty, onChanged: null),
                const SizedBox(width: Tokens.space3),
                const AppCheckbox(value: CheckValue.checked, onChanged: null),
                const SizedBox(width: Tokens.space3),
                const AppCheckbox(value: CheckValue.excluded, onChanged: null),
                const SizedBox(width: Tokens.space5),
                AppCheckbox(
                  value: _plain,
                  onChanged: (v) => setState(() => _plain = v),
                ),
                const SizedBox(width: Tokens.space3),
                AppCheckbox(
                  value: _filter,
                  allowExclude: true,
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ],
            ),
            const SizedBox(height: Tokens.space2),
            const _Note(
              'Left: empty, checked, excluded. Right: two you can click, the '
              'second one cycles through excluded.',
            ),
            const _Section('Panel'),
            const Panel(
              child: Text(
                'A block on the surface color. Square, no border.',
                style: TextStyle(
                  fontFamily: Tokens.sans,
                  fontSize: Tokens.text3,
                  color: Tokens.inkSoft,
                ),
              ),
            ),
            const _Section('Page header'),
            const _PageHeader(),
            const SizedBox(height: Tokens.space2),
            const _Note(
              'One line, centred: the page title and its status switcher, the '
              'layout switch in the middle, the sort on the right. Both menu '
              'buttons open their menu right under themselves.',
            ),
            const _Section('Menus'),
            const _Menus(),
            const _Section('Library rows and cards'),
            const LibraryRowsSection(),
            const _Section('Icons'),
            const _Icons(),
            const SizedBox(height: Tokens.space3),
            const _IconSheet(),
            const SizedBox(height: Tokens.space2),
            const _Note(
              'Straight lines on a fixed grid, only 90 and 45 degrees. '
              'Nekomimi at 20 (logo size) and 96; the score star, the one icon '
              'off the grid, at 16 and 64; Discover at 20 on the amber rail '
              'item.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontFamily: Tokens.sans,
      fontWeight: FontWeight.w700,
      fontSize: Tokens.text4,
      color: Tokens.ink,
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Tokens.space5, bottom: Tokens.space3),
    child: _Heading(title),
  );
}

/// The Library's controls: tabs with a menu tab, sort, the view switch, and the
/// status menu drawn open.
/// The Library's top row, as it is on the page.
class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    // drawn at a desktop width and shrunk to fit a phone, as a picture of
    // the real row
    return Panel(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 900,
          child: Row(
            children: [
              const PageTitle('Library'),
              const SizedBox(width: Tokens.space4),
              AppButton(
                label: 'Watching',
                kind: ButtonKind.secondary,
                opensMenu: true,
                count: 571,
                onPressed: () {},
              ),
              const Spacer(),
              IconSquareButton(
                icon: AppIcons.grid,
                label: 'Grid view',
                selected: true,
                onPressed: () {},
              ),
              const SizedBox(width: Tokens.space1),
              IconSquareButton(
                icon: AppIcons.list,
                label: 'List view',
                onPressed: () {},
              ),
              const Spacer(),
              AppButton(
                label: 'Recent',
                kind: ButtonKind.secondary,
                opensMenu: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The status menu, the sort menu and a row's menu.
class _Menus extends StatelessWidget {
  const _Menus();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Tokens.space5,
      runSpacing: Tokens.space4,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        AppMenu(
          entries: [
            MenuEntry(label: 'All  3357', onPressed: () {}),
            MenuEntry(label: 'Watching  571', selected: true, onPressed: () {}),
            MenuEntry(label: 'Planned  1606', onPressed: () {}),
            MenuEntry(label: 'Completed  2421', onPressed: () {}),
            MenuEntry(label: 'On hold  12', onPressed: () {}),
            MenuEntry(label: 'Dropped  3', onPressed: () {}),
            MenuEntry(label: 'Not interested  40', onPressed: () {}),
          ],
        ),
        AppMenu(
          entries: [
            MenuEntry(label: 'Recent', selected: true, onPressed: () {}),
            MenuEntry(label: 'A to Z', onPressed: () {}),
          ],
        ),
        AppMenu(
          entries: [
            MenuEntry(label: 'Watching', shortcut: '1', onPressed: () {}),
            MenuEntry(label: 'Planned', shortcut: '2', onPressed: () {}),
            MenuEntry(label: 'Completed', shortcut: '3', onPressed: () {}),
            MenuEntry(label: 'On hold', shortcut: '4', onPressed: () {}),
            MenuEntry(label: '+ Episode', onPressed: () {}),
            MenuEntry(label: 'Open details', onPressed: () {}),
            MenuEntry(
              label: 'Remove from list',
              destructive: true,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

/// Every icon by name, drawn large, and the status marks at their real size.
class _IconSheet extends StatelessWidget {
  const _IconSheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Tokens.space5,
          runSpacing: Tokens.space4,
          children: [
            for (final entry in AppIcons.all.entries)
              if (entry.key != 'nekomimi')
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(entry.value, size: 40, color: Tokens.ink),
                    const SizedBox(height: Tokens.space1),
                    _Note(entry.key),
                  ],
                ),
          ],
        ),
        const SizedBox(height: Tokens.space4),
        Wrap(
          spacing: Tokens.space5,
          runSpacing: Tokens.space3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final status in EntryStatus.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusMark(status),
                  const SizedBox(width: Tokens.space2),
                  _Note(status.value),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: Tokens.mono,
      fontSize: Tokens.text2,
      color: Tokens.inkMuted,
    ),
  );
}

class _Icons extends StatelessWidget {
  const _Icons();

  @override
  Widget build(BuildContext context) {
    const mascot = AppIcons.nekomimi;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: Tokens.space3,
      children: [
        const AppIcon(
          mascot,
          size: 20,
          color: Tokens.mint,
          lineColor: Tokens.ground,
        ),
        const SizedBox(width: Tokens.space5),
        const AppIcon(
          mascot,
          size: 96,
          color: Tokens.mint,
          lineColor: Tokens.ground,
        ),
        const SizedBox(width: Tokens.space5),
        const ScoreStar(size: Tokens.iconSize, color: Tokens.amber),
        const SizedBox(width: Tokens.space3),
        const ScoreStar(size: 64, color: Tokens.amber),
        const SizedBox(width: Tokens.space5),
        const ColoredBox(
          color: Tokens.amber,
          child: SizedBox.square(
            dimension: Tokens.railItemSize,
            child: Center(
              child: AppIcon(
                AppIcons.discover,
                size: Tokens.railIconSize,
                color: Tokens.ground,
              ),
            ),
          ),
        ),
        const SizedBox(width: Tokens.space5),
        for (final destination in [...railDestinations, settingsDestination])
          Padding(
            padding: const EdgeInsets.only(right: Tokens.space3),
            child: AppIcon(
              destination.icon,
              size: Tokens.railIconSize,
              color: Tokens.inkMuted,
            ),
          ),
      ],
    );
  }
}

class _Colors extends StatelessWidget {
  const _Colors();

  static const _all = <(String, Color)>[
    ('ground', Tokens.ground),
    ('surface', Tokens.surface),
    ('ink', Tokens.ink),
    ('ink-soft', Tokens.inkSoft),
    ('ink-muted', Tokens.inkMuted),
    ('amber', Tokens.amber),
    ('mint', Tokens.mint),
    ('red', Tokens.red),
  ];

  static String _hex(Color c) =>
      (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Tokens.space3,
      runSpacing: Tokens.space3,
      children: [
        for (final (name, color) in _all)
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The outline keeps ground and surface visible on the page.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: Tokens.inkMuted),
                  ),
                  child: const SizedBox(
                    height: Tokens.controlHeight,
                    width: 96,
                  ),
                ),
                const SizedBox(height: Tokens.space1),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: Tokens.sans,
                    fontSize: Tokens.text2,
                    color: Tokens.ink,
                  ),
                ),
                _Note(_hex(color)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Type extends StatelessWidget {
  const _Type();

  static const _sizes = <(String, double)>[
    ('text1', Tokens.text1),
    ('text2', Tokens.text2),
    ('text3', Tokens.text3),
    ('text4', Tokens.text4),
    ('text5', Tokens.text5),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, size) in _sizes)
          Padding(
            padding: const EdgeInsets.only(bottom: Tokens.space2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 72, child: _Note('$name ${size.toInt()}')),
                // Wraps to a second line on a narrow screen instead of
                // running off the edge.
                Expanded(
                  child: Wrap(
                    spacing: Tokens.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'IBM Plex Sans 0123',
                        style: TextStyle(
                          fontFamily: Tokens.sans,
                          fontSize: size,
                          color: Tokens.ink,
                        ),
                      ),
                      Text(
                        'EP 07 / 24',
                        style: TextStyle(
                          fontFamily: Tokens.mono,
                          fontSize: size,
                          color: Tokens.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Text(
          'Bold sans',
          style: TextStyle(
            fontFamily: Tokens.sans,
            fontWeight: FontWeight.w700,
            fontSize: Tokens.text4,
            color: Tokens.ink,
          ),
        ),
      ],
    );
  }
}

class _Space extends StatelessWidget {
  const _Space();

  static const _steps = <(String, double)>[
    ('space1', Tokens.space1),
    ('space2', Tokens.space2),
    ('space3', Tokens.space3),
    ('space4', Tokens.space4),
    ('space5', Tokens.space5),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, size) in _steps)
          Padding(
            padding: const EdgeInsets.only(bottom: Tokens.space2),
            child: Row(
              children: [
                SizedBox(width: 72, child: _Note('$name ${size.toInt()}')),
                ColoredBox(
                  color: Tokens.amber,
                  child: SizedBox(width: size, height: Tokens.space3),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Sizes extends StatelessWidget {
  const _Sizes();

  static const _all = <(String, double)>[
    ('barHeight', Tokens.barHeight),
    ('railWidth', Tokens.railWidth),
    ('railItemSize', Tokens.railItemSize),
    ('windowButtonWidth', Tokens.windowButtonWidth),
    ('controlHeight', Tokens.controlHeight),
    ('badgeSize', Tokens.badgeSize),
    ('checkboxSize', Tokens.checkboxSize),
    ('touchTarget', Tokens.touchTarget),
    ('scrollbarWidth', Tokens.scrollbarWidth),
    ('resizeEdge', Tokens.resizeEdge),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, value) in _all) _Note('$name ${value.toInt()}'),
      ],
    );
  }
}
