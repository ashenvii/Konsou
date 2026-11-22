import 'package:flutter/painting.dart';

abstract final class Tokens {
  // colors
  // black and garnet, picked by the owner 2026-11-22 from a live rig. Pop is
  // the owner's D83B55 lightened a notch to pass 4.5:1 on every fill; red
  // moved to orange-red to sit well away from pop. Done and live are ink and
  // shape, so there is no second hue.
  static const Color ground = Color(0xFF09090B);
  static const Color ink = Color(0xFFF6F4F5);
  static const Color inkSoft = Color(0xFFCFC9CC);
  static const Color inkMuted = Color(0xFF9A9296);
  // the one bright color: main action, current place, hover, your score
  static const Color pop = Color(0xFFE0526A);
  // text and marks on a pop fill
  static const Color onPop = Color(0xFF1A0509);
  // the ordinary star gold, for MyAnimeList's score only (owner, 2026-11-21)
  static const Color star = Color(0xFFF2B33D);
  static const Color red = Color(0xFFFF7F45);
  // fill of secondary buttons, fields and panels
  static const Color surface = Color(0xFF131315);
  // floating panels and hairlines: halfway between ground and surface
  static const Color raised = Color(0xFF0E0E10);
  static const Color line = Color(0xFF3A383B);
  static const Color shadow = Color(0x8C000000);

  // radius: square for anything flat; the garnet console's raised and sunk
  // parts get small corners (owner, 2026-11-22)
  static const BorderRadius square = BorderRadius.zero;
  static const double coverRadius = 3;
  static const double keyRadius = 5;
  static const double wellRadius = 6;
  static const BorderRadius coverCorners = BorderRadius.all(
    Radius.circular(coverRadius),
  );
  static const BorderRadius keyCorners = BorderRadius.all(
    Radius.circular(keyRadius),
  );
  static const BorderRadius wellCorners = BorderRadius.all(
    Radius.circular(wellRadius),
  );

  // the garnet console (owner, 2026-11-22): chassis and title bar gradients,
  // the faceplate rail, sunk wells, a slab under the primary key, an off lamp,
  // and a faint white lip on raised edges
  static const Color chassisTop = Color(0xFF1D1C20);
  static const Color chassisBottom = Color(0xFF0E0D10);
  static const Color barTop = Color(0xFF211F24);
  static const Color barBottom = Color(0xFF161518);
  static const Color railFill = Color(0xFF121114);
  static const Color wellFill = Color(0xFF050506);
  static const Color popSlab = Color(0xFF8A2537);
  static const Color lampOff = Color(0xFF2A282D);
  static const Color edgeLight = Color(0x0DFFFFFF);
  // raised buttons sit on a 3 slab; key caps keep keyDepth
  static const double buttonDepth = 3;
  static const double wellPad = 6;
  // the gap inside a small display, such as the progress segments' well
  static const double displayInset = 2;
  static const double lampSize = 9;
  // the rail's lit edge and the open watch order cover's ring
  static const double litEdge = 3;
  // glow blur: LED digits, lamps and the lit edge, the open cover
  static const double ledGlow = 6;
  static const double lampGlow = 8;
  static const double openGlow = 14;

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

  // fonts (owner, 2026-11-22): three families, one job each. sans for running
  // text and Japanese names, label for headings, titles, tabs and buttons, mono
  // for every number and key cap. Share Tech Mono has one weight.
  static const String sans = 'PlexSansJP';
  static const String label = 'ChakraPetch';
  static const String mono = 'ShareTechMono';
  // label tracking, as a share of the font size
  static const double labelTracking = 0.02;

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
  static const Color keyFace = Color(0xFF2C2B2E);
  static const Color keySlab = Color(0xFF222124);
  static const double keyDepth = 4;
  static const double keyPadX = 6;
  static const double keyPadY = 2;

  // the quick search button in the top bar
  static const Color wellEdge = Color(0xFF151517);
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
