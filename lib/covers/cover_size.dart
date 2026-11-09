enum CoverSize { medium, large }

/// How many pixels wide MAL's medium file is.
const mediumCoverWidth = 225;

/// The smallest file that is still sharp where the cover is drawn: medium
/// while it fits, large once the screen needs more pixels.
CoverSize chooseCoverSize({
  required double drawnWidth,
  required double pixelRatio,
}) => drawnWidth * pixelRatio > mediumCoverWidth
    ? CoverSize.large
    : CoverSize.medium;
