import 'package:flutter/painting.dart';

abstract final class Tokens {
  // colors
  // scheme 12 of visme.co/blog/website-color-schemes, picked by the owner
  // 2026-11-21: ground, surface, ink, pop and support are its five colors.
  // ink-soft and ink-muted are ink stepped toward ground; red is not in the
  // scheme and is lifted to keep 4.5:1 on surface.
  static const Color ground = Color(0xFF0D0E12);
  static const Color ink = Color(0xFFC5C6CA);
  static const Color inkSoft = Color(0xFFA9AAAE);
  static const Color inkMuted = Color(0xFF8E8F94);
  // the one bright color: main action, current place, your score
  static const Color pop = Color(0xFF6AFBEE);
  // done marks, tags and live counts
  static const Color support = Color(0xFF46A29F);
  static const Color red = Color(0xFFEF5A5F);
  // fill of secondary buttons, fields and panels
  static const Color surface = Color(0xFF1C232B);
  // floating panels and hairlines: halfway between ground and surface
  static const Color raised = Color(0xFF14181E);
  static const Color line = Color(0xFF3A3D44);
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
  static const double text1 = 12;
  static const double text2 = 16;
  static const double text3 = 20;
  static const double text4 = 24;
  static const double text5 = 32;

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
  static const double windowIconSize = 12;

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
  static const double scrollbarWidth = 8;

  static const double resizeEdge = 8;

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
  static const Color keyFace = Color(0xFF2E343C);
  static const Color keySlab = Color(0xFF242A31);
  static const double keyDepth = 4;
  static const double keyPadX = 6;
  static const double keyPadY = 2;

  // the quick search button in the top bar
  static const Color wellEdge = Color(0xFF14161A);
  static const double quickSearchWidth = 280;
  static const double quickSearchHeight = 28;

  // the quick search popover, from the wireframe the owner approved 2026-11-13
  static const double quickPanelWidth = 720;
  static const double quickPanelMaxHeight = 720;
  static const double quickFieldHeight = 52;
  static const double quickFooterHeight = 48;
  static const double quickCoverWidth = 32;

  // the Detail page, layout A of the redo (owner, 2026-11-18)
  // the cover as key art at the top of the Detail page; MAL's covers are
  // about 425 wide and turn soft when drawn much wider
  static const double keyArtMaxWidth = 640;
  // the widest a column of running text gets, about 90 characters
  static const double detailTextWidth = 720;
  // a row of covers that peeks: no cover narrower than this, and the next
  // cover shows this share of its width on the right
  static const double peekItemMinWidth = 112;
  static const double peekShare = 0.4;
  // a trailer's picture in a peeking row is never narrower than this
  static const double videoMinWidth = 240;
  // the watch order rail (owner, 2026-11-19): a state square on a line
  static const double stateSquare = 16;
  static const double railLaneHeight = 24;
  static const double railDash = 4;
  // the pop frame on the open title's cover
  static const double openFrame = 4;

  // line height for text that can wrap onto a second line (owner, 2026-11-13);
  // single-line labels stay at 1 inside their fixed controls.
  static const double lineHeightWrapped = 1.4;

  // motion: a chevron turning, and things that slide or glide (owner, 2026-11-12)
  static const Duration motionQuick = Duration(milliseconds: 160);
  static const Duration motionSlide = Duration(milliseconds: 220);

  // things appearing and going (owner, 2026-11-17): menus and popovers fade in
  // with a small slide down, the toast and tips only fade; ease-out opening,
  // ease-in closing
  static const Duration motionOpen = Duration(milliseconds: 120);
  static const Duration motionClose = Duration(milliseconds: 80);
  static const Duration motionTip = Duration(milliseconds: 100);
  static const double openSlide = 4;
  static const Duration tipDelay = Duration(milliseconds: 400);
}
