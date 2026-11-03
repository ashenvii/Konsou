import { useEffect, useState } from "react";

/**
 * The dominant hue of a piece of cover art, clamped hard enough to paint with.
 *
 * This is the thing that makes a music app feel like it belongs to what you are
 * playing: Spotify's top bar is not a theme colour, it is the album's colour.
 * Measured on their web player, the bar behind a Daft Punk album was
 * rgb(107, 119, 141), which is a heavily desaturated blue-grey — nothing like
 * the vivid blues on the sleeve. That is the important part. They do not use
 * the extracted colour, they use a hard clamp of it.
 *
 * They have to. An arbitrary colour pulled from arbitrary artwork has arbitrary
 * lightness, and fixed ink over a surface of unknown lightness is a contrast
 * failure waiting for the wrong album. Clamping is what turns "the show's
 * colour" from a nice idea into something that can be shipped.
 *
 * So: the HUE comes from the art, and nothing else does.
 */

/** Where a clamped surface lands, and why those two numbers.
 *
 *  L 30% is derived from the ink, not chosen: --color-text-primary is ivory at
 *  L 93%, and it has to clear AA (4.5:1) on whatever this returns. At L 30 the
 *  measured ratio is roughly 8:1, which leaves headroom for the secondary and
 *  tertiary inks too rather than only just passing with the brightest one.
 *
 *  C 0.08 is a ceiling rather than a value: a greyscale poster should produce a
 *  near-grey bar, not a fabricated colourful one. Chroma is carried through
 *  from the art up to this cap and no further. Past roughly 0.09 at this
 *  lightness the surface starts competing with the vermilion stamp, which is
 *  the one ink in this app allowed to be loud.  */
const CLAMP_L = 0.3;
const CLAMP_C_MAX = 0.08;

/** Pixels this dark or this pale carry no usable hue and are almost always
 *  letterboxing, a black bar, or a white studio logo. Sampling them is how you
 *  end up deciding that every cover in existence is grey. */
const MIN_L = 0.18;
const MAX_L = 0.95;
/** Below this the pixel is grey enough that its hue is noise. */
const MIN_C = 0.02;

/** The image is drawn into a box this size before sampling. Cover art is a
 *  poster, not a photograph — a 32px thumbnail keeps every large field of
 *  colour and throws away the detail, and it means the whole scan is ~1000
 *  pixels rather than several hundred thousand. */
const SAMPLE = 32;

/** Hue buckets. Twelve is 30 degrees each: coarse enough that a gradient across
 *  a sky lands in one bucket, fine enough to tell teal from green. */
const BUCKETS = 12;

export interface CoverAccent {
  /** Degrees. The only thing taken from the artwork. */
  h: number;
  /** Already clamped to CLAMP_C_MAX. */
  c: number;
}

/** sRGB (0-255) to OKLab. The standard matrices; see Björn Ottosson's OKLab
 *  derivation, which is also where the app's oklch() tokens come from. */
function srgbToOklab(r: number, g: number, b: number): [number, number, number] {
  const lin = (v: number) => {
    v /= 255;
    return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  };
  const R = lin(r);
  const G = lin(g);
  const B = lin(b);
  const l = Math.cbrt(0.4122214708 * R + 0.5363325363 * G + 0.0514459929 * B);
  const m = Math.cbrt(0.2119034982 * R + 0.6806995451 * G + 0.1073969566 * B);
  const s = Math.cbrt(0.0883024619 * R + 0.2817188376 * G + 0.6299787005 * B);
  return [
    0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s,
  ];
}

/**
 * The dominant hue of an image, or null if it has none worth using.
 *
 * Not an average. Averaging a poster returns mud every time, because opposite
 * hues cancel: a red character on a green field averages to grey. This
 * histograms hue into buckets weighted by chroma AND by how much of the image
 * is in each, so the answer is "the biggest, most saturated field of colour in
 * the picture" rather than "the arithmetic middle of the picture".
 */
function dominant(data: Uint8ClampedArray): CoverAccent | null {
  const weight = new Float64Array(BUCKETS);
  const sumSin = new Float64Array(BUCKETS);
  const sumCos = new Float64Array(BUCKETS);
  const sumC = new Float64Array(BUCKETS);

  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] < 200) continue;
    const [L, a, b] = srgbToOklab(data[i], data[i + 1], data[i + 2]);
    if (L < MIN_L || L > MAX_L) continue;
    const c = Math.sqrt(a * a + b * b);
    if (c < MIN_C) continue;
    const hRad = Math.atan2(b, a);
    const deg = ((hRad * 180) / Math.PI + 360) % 360;
    const k = Math.floor(deg / (360 / BUCKETS)) % BUCKETS;
    // Weighted by chroma: one vivid pixel should count for more than one
    // washed-out pixel, or a large dull background always wins.
    const w = c;
    weight[k] += w;
    sumSin[k] += Math.sin(hRad) * w;
    sumCos[k] += Math.cos(hRad) * w;
    sumC[k] += c * w;
  }

  let best = -1;
  let bestW = 0;
  for (let k = 0; k < BUCKETS; k++) {
    if (weight[k] > bestW) {
      bestW = weight[k];
      best = k;
    }
  }
  if (best < 0 || bestW <= 0) return null;

  // Circular mean inside the winning bucket, so a hue near a bucket edge is not
  // dragged to the bucket's centre.
  const h = ((Math.atan2(sumSin[best], sumCos[best]) * 180) / Math.PI + 360) % 360;
  const c = Math.min(sumC[best] / bestW, CLAMP_C_MAX);
  return { h, c };
}

/**
 * Reads the dominant hue out of a cover URL.
 *
 * Returns null until it has an answer, and stays null if it cannot get one —
 * every caller has to treat "no accent" as the normal case, not as an error.
 * There are three ordinary ways to end up there: no cover, a greyscale cover,
 * and a canvas the browser refuses to read back.
 *
 * That last one is not hypothetical. Covers are served from AniList's CDN, so
 * the read is cross-origin: without a permissive CORS header the canvas is
 * tainted and getImageData throws a SecurityError. The request asks for
 * anonymous CORS and the whole read sits in a try/catch, so a CDN that declines
 * costs a fallback to the untinted surface rather than a broken page.
 */
export function useCoverAccent(url: string | null | undefined): CoverAccent | null {
  const [accent, setAccent] = useState<CoverAccent | null>(null);

  useEffect(() => {
    if (!url) {
      setAccent(null);
      return;
    }
    let cancelled = true;
    // Synchronously true, flipped below — guards against a resolved-from-cache
    // image firing onload before this effect has finished setting up.
    cancelled = false;

    const img = new Image();
    img.crossOrigin = "anonymous";
    img.decoding = "async";
    img.onload = () => {
      if (cancelled) return;
      try {
        const cv = document.createElement("canvas");
        cv.width = SAMPLE;
        cv.height = SAMPLE;
        const ctx = cv.getContext("2d", { willReadFrequently: true });
        if (!ctx) return;
        ctx.drawImage(img, 0, 0, SAMPLE, SAMPLE);
        const { data } = ctx.getImageData(0, 0, SAMPLE, SAMPLE);
        if (!cancelled) setAccent(dominant(data));
      } catch {
        // Tainted canvas, or a decode that produced nothing readable. The
        // surface simply stays untinted.
        if (!cancelled) setAccent(null);
      }
    };
    img.onerror = () => {
      if (!cancelled) setAccent(null);
    };
    img.src = url;

    return () => {
      cancelled = true;
      img.onload = null;
      img.onerror = null;
    };
  }, [url]);

  return accent;
}

/** The clamped surface colour, ready to paint. Hue from the art, lightness
 *  fixed by the contrast requirement, chroma carried but capped. */
export function accentSurface(a: CoverAccent | null): string | null {
  return a ? `oklch(${CLAMP_L * 100}% ${a.c.toFixed(3)} ${a.h.toFixed(1)})` : null;
}

/**
 * The halo: the poster's colour thrown onto the surface behind it.
 *
 * Brighter and much more saturated than the plate glow, because this is not a
 * tint on a panel — it is meant to read as light coming off the artwork. It is
 * always painted as a soft radial gradient and never as a blurred element:
 * `filter: blur()` on a box this size is a full-surface raster on every frame
 * it changes, and this app already has a note about what per-frame surface work
 * costs on phone GPUs. A radial gradient with soft stops is the same picture
 * with none of that, and it composites.
 */
export function accentHalo(a: CoverAccent | null): string | null {
  return a
    ? `oklch(72% ${Math.min(a.c * 2.4, 0.19).toFixed(3)} ${a.h.toFixed(1)} / 16%)`
    : null;
}
