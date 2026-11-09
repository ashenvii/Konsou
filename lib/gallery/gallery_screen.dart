import 'package:flutter/widgets.dart';

import '../components/app_button.dart';
import '../components/app_checkbox.dart';
import '../components/app_tab.dart';
import '../components/count_badge.dart';
import '../components/panel.dart';
import '../design/tokens.dart';
import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
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
        padding: const EdgeInsets.all(Tokens.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Heading('Gallery', size: Tokens.text5),
            const _Note('Every token and component built so far.'),
            const _Section('Colors'),
            const _Colors(),
            const _Section('Type'),
            const _Type(),
            const _Section('Space'),
            const _Space(),
            const _Section('Shell sizes'),
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
            const _Section('Icons'),
            const _Icons(),
            const SizedBox(height: Tokens.space2),
            const _Note(
              'Straight lines on a fixed grid, only 90 and 45 degrees. '
              'Nekomimi at 20 (logo size) and 96; Discover at 20 on the amber '
              'rail item.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.size = Tokens.text4});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontFamily: Tokens.sans,
      fontWeight: FontWeight.w700,
      fontSize: size,
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
