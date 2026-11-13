import 'package:flutter/painting.dart';

abstract final class Tokens {
  // colors
  static const Color ground = Color(0xFF080D10);
  static const Color ink = Color(0xFFF4F5F5);
  static const Color inkSoft = Color(0xFFBCC1C4);
  static const Color inkMuted = Color(0xFF748992);
  static const Color amber = Color(0xFFF2B33D);
  static const Color mint = Color(0xFF3DD6A0);
  static const Color red = Color(0xFFE94D52);
  // fill of secondary buttons, fields and panels (approved 2026-11-08).
  static const Color surface = Color(0xFF0F1F25);
  // floating panels and hairlines: even OKLCH steps at ground's hue (owner, 2026-11-12)
  static const Color raised = Color(0xFF121B20);
  static const Color line = Color(0xFF262F35);
  static const Color shadow = Color(0x8C000000);

  // radius: square everywhere
  static const BorderRadius square = BorderRadius.zero;

  // space
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;

  // type sizes
  static const double text1 = 11;
  static const double text2 = 12;
  static const double text3 = 14;
  static const double text4 = 18;

  // fonts
  static const String sans = 'PlexSans';
  static const String mono = 'PlexMono';

  // shell sizes from the comp (2026-11-08); windowIconSize is not measured
  static const double barHeight = 36;
  static const double railWidth = 48;
  static const double railItemSize = 36;
  // one size for every icon (owner, 2026-11-12)
  static const double iconSize = 20;
  static const double windowButtonWidth = 40;
  static const double windowIconSize = 10;

  // component sizes from the comp (2026-11-08); focusRing is not in it
  static const double controlHeight = 36;
  static const double badgeSize = 16;
  static const double checkboxSize = 20;
  static const double checkboxBorder = 2;
  static const double focusRing = 2;
  static const double hoverEdge = 2;
  static const double shadowBlur = 24;
  static const double shadowDrop = 8;
  // smallest area a finger can hit, on touch screens (Android guideline).
  static const double touchTarget = 48;
  static const double scrollbarWidth = 10;

  static const double resizeEdge = 6;

  // the Library, first guesses from the loading screenshot, to be tuned.
  static const double gridCardMinWidth = 168;
  static const double listRowHeight = 72;
  static const double listCoverWidth = 40;

  // the toast, a first guess the owner agreed to (2026-11-12).
  static const double toastMaxWidth = 480;
  // the bar on a toast that shows its time left.
  static const double toastBarHeight = 2;

  // the Library's Find field, a first guess for the owner to tune.
  static const double findFieldWidth = 240;

  // key cap C, locked by the owner 2026-11-13: a face and a slab under it
  static const Color keyFace = Color(0xFF303B42);
  static const Color keySlab = Color(0xFF262F35);
  static const double keyDepth = 4;
  static const double keyPadX = 6;
  static const double keyPadY = 2;

  // the quick search button in the top bar
  static const Color wellEdge = Color(0xFF030608);
  static const double quickSearchWidth = 280;
  static const double quickSearchHeight = 28;

  // the quick search popover, from the wireframe the owner approved 2026-11-13
  static const double quickPanelWidth = 560;
  static const double quickPanelMaxHeight = 520;
  static const double quickFieldHeight = 52;
  static const double quickFooterHeight = 48;
  static const double quickCoverWidth = 30;

  // line height for text that can wrap onto a second line (owner, 2026-11-13);
  // single-line labels stay at 1 inside their fixed controls.
  static const double lineHeightWrapped = 1.4;

  // motion: a chevron turning, and things that slide or glide (owner, 2026-11-12)
  static const Duration motionQuick = Duration(milliseconds: 160);
  static const Duration motionSlide = Duration(milliseconds: 220);
}
