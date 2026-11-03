/**
 * Little anime facts and app tips for the quiet corners of the UI (Stats
 * footer, empty states). All static and offline, no API. Rotates by the day so
 * it feels alive without churning mid-session, with a random picker for spots
 * that want variety on every mount.
 */
export interface Trivia {
  text: string;
  /** A tiny glyph/kaomoji accent. Kept optional so surfaces can drop it. */
  glyph?: string;
}

const ANIME_FACTS: Trivia[] = [
  { text: "Spirited Away was the first hand-drawn film to win the Oscar for Best Animated Feature.", glyph: "✧" },
  { text: "In Japan the word anime just means animation, Tom and Jerry included.", glyph: "♪" },
  { text: "Sazae-san has aired new episodes every week since 1969, the longest run of any anime.", glyph: "☆" },
  { text: "Studio Ghibli took its name from an Italian aircraft, the Caproni Ghibli.", glyph: "✈" },
  { text: "Cowboy Bebop's opening theme, Tank!, was cut live by a full big band called the Seatbelts.", glyph: "♫" },
  { text: "Akira's team hand-drew over 160,000 frames back in 1988, unheard of at the time.", glyph: "✧" },
  { text: "Hayao Miyazaki has announced his retirement more times than most people change jobs.", glyph: "(－‸ლ)" },
  { text: "Astro Boy in 1963 set the weekly TV format the whole industry still runs on.", glyph: "☆" },
  { text: "Goku has had the same Japanese voice, Masako Nozawa, since 1989.", glyph: "★" },
  { text: "Attack on Titan was turned down once before a different magazine took the gamble.", glyph: "⚔" },
  { text: "One Piece has run for over 25 years and still hasn't reached its final island.", glyph: "☠" },
  { text: "Pokemon grew out of a kid's hobby: Satoshi Tajiri collected bugs.", glyph: "✧" },
  { text: "Evangelion's finale leaned on stills and inner monologue partly because the budget ran dry.", glyph: "◇" },
  { text: "Crunchyroll began in 2006 as a scrappy site for fan uploads.", glyph: "♪" },
];

const APP_TIPS: Trivia[] = [
  { text: "Konsou keeps an eye on your finished shows and pings you the moment a sequel is announced.", glyph: "(ノ◕ヮ◕)ノ" },
  { text: "Seasons of the same show fold into one card. Tap it to see the whole run.", glyph: "☆" },
  { text: "Flip Discover between Grid, List, and Compact with the view button.", glyph: "▦" },
  { text: "Stack genre, format, year, and country in the Discover filters to find exactly what you want.", glyph: "✧" },
  { text: "Rate what you watch and your Stats page draws the score curve for you.", glyph: "★" },
  { text: "The Alerts tab is your sequel radar: airing now, upcoming, and the ones you nearly missed.", glyph: "✦" },
];

/** Days since the start of the year — the seed for the daily rotation. */
function dayIndex(): number {
  const now = new Date();
  const start = new Date(now.getFullYear(), 0, 0).getTime();
  return Math.floor((now.getTime() - start) / 86_400_000);
}

/** Today's anime fact — stable for the whole day. */
export function dailyFact(): Trivia {
  return ANIME_FACTS[dayIndex() % ANIME_FACTS.length];
}

/** Today's app tip — stable for the whole day. */
export function dailyTip(): Trivia {
  return APP_TIPS[dayIndex() % APP_TIPS.length];
}

/** A fresh fact each call, for surfaces that want variety on every mount. */
export function randomFact(): Trivia {
  return ANIME_FACTS[Math.floor(Math.random() * ANIME_FACTS.length)];
}
