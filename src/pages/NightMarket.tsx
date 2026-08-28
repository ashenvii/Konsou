import { useEffect, useMemo, useRef, useState } from "react";
import { ChevronRight, Play } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { Icon } from "@/components/ui/Icon";
import "@/styles/night-market.css";
import { CompletedBoard } from "@/components/list/CompletedBoard";
import { DRAWER_ITEMS, WatchDrawer } from "@/components/list/WatchDrawer";
import { accentHalo, useCoverAccent } from "@/hooks/useCoverAccent";
import { useDebounce } from "@/hooks/useDebounce";
import { useFrozenOrder } from "@/hooks/useFrozenOrder";
import { useMediaQuery } from "@/hooks/useMediaQuery";
import { groupEntries } from "@/lib/franchise/grouping";
import { statusMeta } from "@/components/anime/statusMeta";
import { getCoverUrl, normalizeForSearch, preferredTitle } from "@/lib/format";
import { useCompletionStore } from "@/lib/store/completionStore";
import { useListStore } from "@/lib/store/listStore";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { CSSProperties, RefObject } from "react";
import type { FranchiseGroup } from "@/lib/franchise/grouping";
import type { AnimeListEntry, ListStatus, TitleLanguage } from "@/types/list";

/**
 * My List — the Night Market Overview.
 *
 * Structure from `docs/mockups/overview_structure_v2.html`, skin and
 * component composition from `docs/mockups/overview_skin_wide.html`, rules
 * from `docs/OVERVIEW_NIGHT_MARKET_PLAN.md`. Nothing is carried over from
 * the page this replaces.
 *
 * The surface is four things in reading order. TONIGHT is the one open
 * stall: the show you are about to log, the only element with the highlight
 * border and the only unprompted glow. THE STRIP is everything else
 * running, and its footer line is the Watching room's only door. THE
 * BACKDROP is a darker field that families the two anchors, Completed and
 * Planned, without merging them into one card. MY ORDER stands beside the
 * backdrop as its own column, because a sequence you built by hand is not a
 * count you glance at.
 *
 * The two-hue rule runs through all of it. Signage says "this is filed
 * here"; highlight says "this is open right now". Each surface borrows
 * exactly one accent of the hue it is not — Tonight's border is highlight
 * but its committing action is filled signage, and the strip's border is
 * signage but its progress meters are highlight. That single crossover is
 * what stops a two-colour system reading flat.
 */

/** How many order rows stand in the column before it out-grows the
 *  backdrop beside it. The whole order lives one tap away on its own page. */
const ORDER_ROWS = 4;

/** Covers printed on an anchor card. Four is what the comp draws, and it is
 *  a face, not an inventory. */
const CARD_COVERS = 4;
/** How deep the Completed board's cover pool may go. It shows up to 56 tiles
 *  at once and wants a free list well past that; see CompletedBoard's POOL. */
const BOARD_COVERS = 140;

/** How many of the running shows the drawer carries. Twelve was twelve
 *  MOUNTED, of which the billboard ever showed five; the count now matches
 *  what is actually drawn. The room behind the door holds the rest and the
 *  door says how many that is. Lives in WatchDrawer, next to the thing that
 *  has to render them. */

/** Past this an episode-per-cell record stops being readable and starts being
 *  a texture, so the subject falls back to a plain bar. */
const EPISODE_CELL_CAP = 64;

/** Mirrors the app's own fallback runtime for an episode with no recorded
 *  duration, used only for the backlog figure. */
const MINUTES_PER_EP = 24;

/** How many matches the overlay renders before it asks you to narrow down.
 *  A query over a few thousand entries can match hundreds; this panel is
 *  for finding one thing, not for browsing. */
const FIND_LIMIT = 40;

/** What each status is called in the results panel. The room's own name,
 *  so the answer to "have you seen it?" is also directions to it. */
const STATUS_WORD: Record<string, string> = {
  watching: "watching",
  rewatching: "rewatching",
  completed: "completed",
  plan_to_watch: "planned",
  on_hold: "paused",
  dropped: "dropped",
  not_interested: "muted",
};

const MONTHS = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

function monthYear(ms: number): string {
  const d = new Date(ms);
  return `${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}

function titleOf(g: FranchiseGroup, lang: TitleLanguage): string {
  const root = g.entries.find((e) => e.anilist_id === g.rootId) ?? g.entries[0];
  return preferredTitle(
    { romaji: root.title_romaji, english: root.title_english, native: root.title_native },
    lang,
  );
}

function titleOfEntry(e: AnimeListEntry, lang: TitleLanguage): string {
  return preferredTitle(
    { romaji: e.title_romaji, english: e.title_english, native: e.title_native },
    lang,
  );
}

/** Stable identity for a franchise card across re-sorts. */
const groupKey = (g: FranchiseGroup) => g.rootId;

function groupsFor(entries: AnimeListEntry[], statuses: ListStatus[]): FranchiseGroup[] {
  const wanted = new Set(statuses);
  return groupEntries(entries.filter((e) => wanted.has(e.status)));
}

/** A still-airing show's real ceiling is what has aired, not its eventual
 *  total. The store enforces this; this keeps the button honest about what
 *  a tap would actually do. */
function ceilingOf(e: AnimeListEntry): number | null {
  return e.airing_status === "RELEASING" && e.aired_episodes != null
    ? Math.min(e.total_episodes ?? e.aired_episodes, e.aired_episodes)
    : e.total_episodes;
}

/**
 * Flat art. Its own element rather than the app's shared cover component:
 * this surface controls its own frame, radius and fallback, and a glow only
 * ever belongs to art that actually loaded.
 */
function NmArt({ src, className }: { src: string | null; className: string }) {
  const url = getCoverUrl({ medium: src ?? undefined });
  return (
    <span className={className} aria-hidden>
      {url ? <img src={url} alt="" loading="lazy" decoding="async" /> : null}
    </span>
  );
}

/** Which display step a title gets.
 *
 *  The display step exists for the ONE subject of a surface, and 44px is the
 *  size a SHORT name wants. Set a 96-character light-novel title at 44px in a
 *  head column and you get twelve lines and a 694px plate: measured, at a
 *  1103px window, on "Rich Girl Caretaker: I'm Secretly the Caregiver of the
 *  Most Popular Girl in This Rich Kid School".
 *
 *  Every newspaper on earth solves this the same way and it is not by making
 *  the column wider: a long headline is SET SMALLER. The steps are the app's
 *  own scale, so a long title still lands on the ladder rather than on a
 *  bespoke size.
 *
 *  The thresholds are the point where a step stops fitting three lines in the
 *  NARROWEST head column the grid ever hands out (measured: 394px at a 1280px
 *  window). Going further down the ladder than this is its own mistake — the
 *  first pass dropped a 96-character title to 20px, which fits beautifully and
 *  reads as a caption. The subject of the surface has to stay the size of a
 *  subject; three lines of display type IS the presence, not a failure of it.
 */
function titleStep(title: string): "full" | "long" | "xlong" {
  const n = title.length;
  if (n <= 58) return "full";
  if (n <= 96) return "long";
  return "xlong";
}

/** A cover URL, reduced to characters that cannot break out of a `url("…")`
 *  token in an inline style.
 *
 *  A whitelist, not a blacklist: an inline custom property is parsed as CSS, and
 *  a declaration that terminates early does not fail loudly, it just paints
 *  something nobody wrote. Everything a real CDN cover URL is made of survives;
 *  quotes, brackets, backslashes and whitespace do not.
 */
function sanitizeCssUrl(url: string): string {
  return url.replace(/[^A-Za-z0-9:/._~?&=%+-]/g, "");
}

/**
 * The cursor mechanism's JS half (plan §5a, locked).
 *
 * Publishes --gx/--gy (cursor position in each [data-fx] element's own box)
 * and --fx-mix (1 inside the box, 0 at FX_RADIUS away) as inline custom
 * properties; the CSS reads them for the masked line invert and the
 * localized glow shift. One listener on the page root, re-querying per move
 * so elements that mount and unmount with the data are always covered.
 */
function useCursorFx(rootRef: RefObject<HTMLDivElement | null>) {
  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;
    const FX_RADIUS = 190;
    const clear = () => {
      root.querySelectorAll<HTMLElement>("[data-fx]").forEach((el) => {
        el.style.setProperty("--gx", "-999px");
        el.style.setProperty("--gy", "-999px");
        el.style.setProperty("--fx-mix", "0%");
      });
    };
    const onMove = (e: MouseEvent) => {
      root.querySelectorAll<HTMLElement>("[data-fx]").forEach((el) => {
        const r = el.getBoundingClientRect();
        el.style.setProperty("--gx", `${e.clientX - r.left}px`);
        el.style.setProperty("--gy", `${e.clientY - r.top}px`);
        const dx = Math.max(r.left - e.clientX, 0, e.clientX - r.right);
        const dy = Math.max(r.top - e.clientY, 0, e.clientY - r.bottom);
        const dist = Math.sqrt(dx * dx + dy * dy);
        const mix = Math.max(0, Math.min(1, 1 - dist / FX_RADIUS));
        el.style.setProperty("--fx-mix", `${Math.round(mix * 100)}%`);
      });
    };
    root.addEventListener("mousemove", onMove);
    root.addEventListener("mouseleave", clear);
    return () => {
      root.removeEventListener("mousemove", onMove);
      root.removeEventListener("mouseleave", clear);
    };
  }, [rootRef]);
}

/**
 * The pointer lamp: the room brightens where you are pointing.
 *
 * Tonight has no border any more, so the cursor mechanism has no line to
 * invert on it. The response moves from the line to the light, which means the
 * lit region of the page needs a soft bright spot that follows the pointer.
 *
 * IT MOVES BY TRANSFORM, AND THAT IS THE WHOLE DESIGN. The obvious build is a
 * radial-gradient whose centre is a custom property, the way the card-scoped
 * `--gx`/`--gy` mechanism works. On a card that is a small repaint. On a
 * surface this size it is a full-width raster on every mousemove, which is the
 * same mistake this project already paid for once by driving a scroll value
 * through a `:root` variable at roughly 40ms a frame. A fixed-size element
 * moved with translate3d never repaints at all; the compositor just puts the
 * existing texture somewhere else.
 *
 * Coalesced to one rAF per frame, off entirely without a hover-capable pointer
 * or under reduced motion, and it never touches layout.
 */
function usePointerLamp(
  stageRef: RefObject<HTMLDivElement | null>,
  lampRef: RefObject<HTMLDivElement | null>,
) {
  useEffect(() => {
    const stage = stageRef.current;
    const lamp = lampRef.current;
    if (!stage || !lamp) return;
    if (!window.matchMedia("(hover: hover)").matches) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    /* Half of the lamp's own width, so the translate centres it on the
       pointer rather than hanging it off the top-left corner. */
    const HALF = 320;
    let frame = 0;
    let x = 0;
    let y = 0;

    const place = () => {
      frame = 0;
      lamp.style.transform = `translate3d(${x - HALF}px, ${y - HALF}px, 0)`;
    };
    const onMove = (e: MouseEvent) => {
      const r = stage.getBoundingClientRect();
      x = e.clientX - r.left;
      y = e.clientY - r.top;
      lamp.style.opacity = "1";
      if (!frame) frame = requestAnimationFrame(place);
    };
    const onLeave = () => {
      lamp.style.opacity = "0";
    };

    stage.addEventListener("mousemove", onMove);
    stage.addEventListener("mouseleave", onLeave);
    return () => {
      stage.removeEventListener("mousemove", onMove);
      stage.removeEventListener("mouseleave", onLeave);
      if (frame) cancelAnimationFrame(frame);
    };
  }, [stageRef, lampRef]);
}

/** What Tonight is, normalised so the plate does not care where its subject
 *  came from. Running, paused, and "next in the order you built" are three
 *  routes to the same question: what are you about to watch. */
interface ThreadEntry {
  id: number;
  title: string;
  status: ListStatus;
  watched: number;
  total: number | null;
  /** The one the subject itself is. */
  current: boolean;
}

interface Subject {
  /** The eyebrow chip's word. Names the state, which is what the chip is for. */
  state: string;
  title: string;
  cover: string | null;
  watched: number;
  total: number | null;
  /** null when nothing is known about length — no invented meter. */
  percent: number | null;
  /** Episodes actually broadcast, when known. Separates "behind by two" from
   *  "caught up and waiting", which a percentage cannot express. */
  aired: number | null;
  /** The rest of the franchise you keep, or null for a standalone. */
  thread: ThreadEntry[] | null;
  /** The trailing half of the meta line, after the episode count. */
  note: string | null;
  actionLabel: string;
  /** Spelled out for a screen reader, which cannot see the title above it. */
  actionHint: string;
  disabled: boolean;
  onAct: () => void;
  onOpen: () => void;
}

export function NightMarket() {
  const navigate = useNavigate();
  const rootRef = useRef<HTMLDivElement>(null);
  useCursorFx(rootRef);
  const stageRef = useRef<HTMLDivElement>(null);
  const lampRef = useRef<HTMLDivElement>(null);
  usePointerLamp(stageRef, lampRef);

  const loaded = useListStore((s) => s.loaded);
  const entries = useListStore((s) => s.entries);
  const incrementEpisodes = useListStore((s) => s.incrementEpisodes);
  const updateStatus = useListStore((s) => s.updateStatus);
  const completionEvents = useCompletionStore((s) => s.events);
  const alerts = useNotificationStore((s) => s.items);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  /* One structural line, at 719: below it there is no backdrop and no order
     column, because neither survives a phone. Above it the arrangement is
     one rule all the way up. */
  const isPhone = useMediaQuery("(max-width: 719px)");
  /* Where the order stops fitting beside the backdrop. Below this it keeps
     its own container and simply stands full width underneath. */

  const go = (path: string) => navigate(path, { replace: true });

  /* Cross-status search: the memory job, and the one thing on this page
     that must not care which room a title is filed in. It is a reveal
     rather than a permanent field — the census line hands its own row over
     when asked, so opening and closing search never moves the page under
     you, and Tonight keeps the space it exists to dominate. */
  const [searchOpen, setSearchOpen] = useState(false);
  const [query, setQuery] = useState("");
  const searchRef = useRef<HTMLInputElement>(null);
  const debounced = useDebounce(query, 200);
  const needle = normalizeForSearch(debounced);
  const searching = needle.length > 0;

  useEffect(() => {
    if (searchOpen) searchRef.current?.focus();
  }, [searchOpen]);

  const closeSearch = () => {
    setQuery("");
    setSearchOpen(false);
  };

  /* Built only while a search is actually running, and cached against the
     identity of the array it came from. The index is a normalize pass over
     every title in the library; keying it on `entries` unconditionally
     meant logging a single episode rebuilt the whole thing, on the app's
     most-pressed control. Writing during render is safe here because the
     cache is a pure function of its key. */
  const indexRef = useRef<{ src: AnimeListEntry[]; groups: FranchiseGroup[]; hay: string[] } | null>(
    null,
  );
  const matches = useMemo(() => {
    if (!searching) return [];
    let idx = indexRef.current;
    if (!idx || idx.src !== entries) {
      const groups = groupEntries(entries);
      const hay = groups.map((g) => {
        let s = "";
        for (const e of g.entries) {
          s += `${e.title_romaji} ${e.title_english ?? ""} ${e.title_native ?? ""} `;
        }
        return normalizeForSearch(s);
      });
      idx = { src: entries, groups, hay };
      indexRef.current = idx;
    }
    const out: FranchiseGroup[] = [];
    for (let i = 0; i < idx.groups.length; i++) {
      if (idx.hay[i].includes(needle)) out.push(idx.groups[i]);
      if (out.length >= FIND_LIMIT) break;
    }
    return out;
  }, [searching, needle, entries]);

  /* Running, paused sunk to the bottom: a paused show has not been touched
     lately by definition, so recency alone would float it. */
  const watchingByRecency = useMemo(() => {
    const groups = groupsFor(entries, ["watching", "rewatching", "on_hold"]);
    return groups.sort((a, b) => {
      const paused =
        Number(a.displayEntry.status === "on_hold") -
        Number(b.displayEntry.status === "on_hold");
      return paused !== 0 ? paused : b.sortUpdated - a.sortUpdated;
    });
  }, [entries]);
  /* Sorted on arrival, then held still. Without this, logging an episode
     makes that show the most recent, so it jumps to the subject and every
     card in the rail shifts one place left under your finger: tap twice in
     the same spot and you have logged two different shows. This is the same
     device both rooms already use, not a second one written for this page. */
  const frozenWatching = useFrozenOrder(watchingByRecency, groupKey, "watching");
  const watching = frozenWatching.items;

  const planGroups = useMemo(() => groupsFor(entries, ["plan_to_watch"]), [entries]);

  /** The watch order proper: what you numbered by hand. */
  const numberedOrder = useMemo(
    () =>
      entries
        .filter((e) => e.status === "plan_to_watch" && e.plan_rank != null)
        .sort((a, b) => (a.plan_rank ?? 0) - (b.plan_rank ?? 0)),
    [entries],
  );
  const isNumbered = numberedOrder.length > 0;

  /** The rows the column shows: your numbers when you set any, otherwise
   *  the plan's own order as a quiet index. */
  const orderRows = useMemo(
    () =>
      (isNumbered
        ? numberedOrder.map((e, i) => ({
            id: e.anilist_id,
            n: e.plan_rank ?? i + 1,
            cover: e.cover_url,
            title: titleOfEntry(e, titleLanguage),
          }))
        : planGroups.map((g, i) => ({
            id: g.displayEntry.anilist_id,
            n: i + 1,
            cover: g.displayEntry.cover_url,
            title: titleOf(g, titleLanguage),
          }))
      ).slice(0, ORDER_ROWS),
    [isNumbered, numberedOrder, planGroups, titleLanguage],
  );

  /* Counted as ENTRIES, not franchise groups: every other figure on this
     page counts titles, and a group count wearing the same word drifts on
     its own as the grouper learns which titles are relations. */
  const counts = useMemo(() => {
    let planned = 0;
    let watchingTitles = 0;
    let airing = 0;
    let tracked = 0;
    let since = Number.POSITIVE_INFINITY;
    let backlogMinutes = 0;
    for (const e of entries) {
      if (e.status === "not_interested") continue;
      tracked++;
      if (e.added_at < since) since = e.added_at;
      if (e.status === "plan_to_watch") {
        planned++;
        backlogMinutes += (e.total_episodes ?? 0) * (e.episode_duration ?? MINUTES_PER_EP);
      }
      if (e.status === "watching" || e.status === "rewatching" || e.status === "on_hold") {
        watchingTitles++;
        if (e.airing_status === "RELEASING") airing++;
      }
    }
    return {
      planned,
      watchingTitles,
      airing,
      tracked,
      since: since === Number.POSITIVE_INFINITY ? null : since,
      backlogHours: Math.round(backlogMinutes / 60),
    };
  }, [entries]);

  /* Distinct titles in the archive, from the ledger AND the list together:
     rewatches collapse back to one title, and a completion whose entry was
     removed is still part of the record. */
  const archived = useMemo(() => {
    const ids = new Set<number>();
    for (const ev of completionEvents) ids.add(ev.anilist_id);
    for (const e of entries) if (e.status === "completed") ids.add(e.anilist_id);
    return ids.size;
  }, [completionEvents, entries]);

  /* What the board tops its wall up FROM, which is why it is no longer an
     either/or and no longer four. It used to hand over the completion log when
     there was one and the entries only when there was not, sliced to four
     covers either way. The board draws forty to fifty-six tiles, so a shallow
     log left it repeating nine pictures under a chit reading two hundred. The
     entries are the second source, always, and the board dedupes across both. */
  const completedCovers = useMemo(
    () =>
      groupsFor(entries, ["completed"])
        .slice(0, BOARD_COVERS)
        .map((g) => g.displayEntry.cover_url),
    [entries],
  );

  /* What the board's ledger states. Both fall out of the completion log,
     which is already loaded; neither needs a query. Hours are counted from
     the episodes as recorded at the time, not from the entry's total, so a
     show dropped at eight of twenty-four contributes eight. */
  const finishedStats = useMemo(() => {
    const year = new Date().getFullYear();
    let mins = 0;
    let thisYear = 0;
    let rewatched = 0;
    for (const ev of completionEvents) {
      mins += ev.episodes_at_completion * (ev.episode_duration ?? MINUTES_PER_EP);
      if (new Date(ev.completed_at).getFullYear() === year) thisYear += 1;
      if (ev.rewatch_index > 0) rewatched += 1;
    }
    return { hours: Math.round(mins / 60), thisYear, rewatched };
  }, [completionEvents]);

  const plannedCovers = useMemo(
    () => planGroups.slice(0, CARD_COVERS).map((g) => g.displayEntry.cover_url),
    [planGroups],
  );

  /* Tonight. Whatever is running leads; with nothing running the head of
     the order takes the plate, because "what's next" is the same question
     asked one step earlier. */
  const subject: Subject | null = useMemo(() => {
    const g = watching[0];
    if (g) {
      const e = g.displayEntry;
      const title = titleOf(g, titleLanguage);
      const paused = e.status === "on_hold";
      const ceiling = ceilingOf(e);
      const finished = e.total_episodes != null && e.episodes_watched >= e.total_episodes;
      const caughtUp = !finished && ceiling != null && e.episodes_watched >= ceiling;
      return {
        state: paused ? "Paused" : finished ? "Ready to finish" : caughtUp ? "Caught up" : "Watching now",
        title,
        cover: e.cover_url,
        watched: e.episodes_watched,
        total: e.total_episodes,
        /* Episodes actually broadcast. It is what separates "you are behind by
           two" from "you are caught up and waiting", which a progress bar
           cannot say and which is most of what you want to know about a show
           that is still airing. */
        aired: e.aired_episodes,
        /* The rest of the franchise you track, when there is one. Ordered as
           the grouper orders it (by when you added each entry) and labelled by
           STATE rather than as a watch order: release dates are not stored
           locally, and a sequence this surface cannot verify is worse than no
           sequence. What is true either way is how many you have finished,
           which one is running, and how many are still ahead. */
        thread:
          g.entries.length > 1
            ? g.entries.map((m) => ({
                id: m.anilist_id,
                title: titleOfEntry(m, titleLanguage),
                status: m.status,
                watched: m.episodes_watched,
                total: m.total_episodes,
                current: m.anilist_id === e.anilist_id,
              }))
            : null,
        percent:
          e.total_episodes && e.total_episodes > 0
            ? Math.min(100, Math.round((e.episodes_watched / e.total_episodes) * 100))
            : null,
        note: paused
          ? "paused"
          : e.airing_status === "RELEASING"
            ? caughtUp
              ? "still airing · no new episode yet"
              : "still airing"
            : null,
        actionLabel: paused
          ? "Resume"
          : finished
            ? "Mark complete"
            : caughtUp
              ? "Caught up"
              : "Log episode",
        actionHint: paused
          ? `Resume watching ${title}`
          : finished
            ? `Mark ${title} complete`
            : caughtUp
              ? `${title} is caught up, no new episode has aired`
              : `Log episode ${e.episodes_watched + 1} of ${title}`,
        disabled: caughtUp,
        onAct: paused
          ? () => void updateStatus(e.anilist_id, "watching")
          : finished
            ? () => void updateStatus(e.anilist_id, "completed")
            : () => void incrementEpisodes(e.anilist_id, 1),
        onOpen: () => go(`/anime/${e.anilist_id}`),
      };
    }
    const next = orderRows[0];
    if (!next) return null;
    return {
      state: isNumbered ? "Next in your order" : "From planned",
      title: next.title,
      cover: next.cover,
      watched: 0,
      total: null,
      percent: null,
      aired: null,
      thread: null,
      note: "not started",
      actionLabel: "Start watching",
      actionHint: `Start watching ${next.title}`,
      disabled: false,
      onAct: () => void updateStatus(next.id, "watching"),
      onOpen: () => go(`/anime/${next.id}`),
    };
    // `go` is stable enough for this page's lifetime; navigate identity is
    // not a meaningful dependency here.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [watching, orderRows, isNumbered, titleLanguage, incrementEpisodes, updateStatus]);

  /* The subject's own light, thrown onto the page rather than onto a band.
     Hue from the artwork, lightness clamped, painted as a gradient rather than
     a blurred element, which is the device `useCoverAccent` exists for.

     The clamped BED is gone with the plate that needed it. It was the colour
     of a scrim, and the room has no plate-wide scrim to tint; what is left is
     the halo, which is light and belongs on the wash. */
  const subjectLight = accentHalo(useCoverAccent(subject?.cover));

  /* One resolved cover URL for the whole plate. The poster panel and the
     backdrop cast ask for the same file, so the browser fetches it once, and
     the large size is the one worth asking for: a backdrop blown across a
     1300px band from the medium crop shows its own pixels. If large 404s the
     poster falls back to medium on its own and the backdrop simply does not
     paint, which is the plate the page had before any of this. */
  const subjectCoverBase = getCoverUrl({ medium: subject?.cover ?? undefined });
  const subjectCover = subjectCoverBase
    ? subjectCoverBase.replace("/cover/medium/", "/cover/large/")
    : "";

  /** Everything running that is not the subject. */
  const stripGroups = watching.slice(1, 1 + DRAWER_ITEMS);
  if (!loaded) {
    return (
      <div className="nm konsou-scroll" ref={rootRef}>
        <div className="nm__stage">
          <p className="nm-census">Opening your list…</p>
          <div className="nm-skel nm-skel--tonight" />
          <div className="nm-skel nm-skel--strip" />
        </div>
      </div>
    );
  }

  if (counts.tracked === 0) {
    return (
      <div className="nm konsou-scroll" ref={rootRef}>
        <div className="nm__stage">
          <p className="nm-census">My List</p>
          <div className="nm-empty" data-fx>
            <p className="nm-empty__title">Your collection starts here</p>
            <p className="nm-empty__line">
              Track what you are watching, planning, or have finished. No score required.
            </p>
            <button type="button" className="nm-act" onClick={() => go("/discover")}>
              Find something
            </button>
          </div>
        </div>
      </div>
    );
  }

  const census = `My List — ${counts.tracked.toLocaleString()} ${
    counts.tracked === 1 ? "title" : "titles"
  }${counts.since ? `, kept since ${monthYear(counts.since)}` : ""}`;

  /* Completed is a WALL OF THE COVERS YOU HAVE FINISHED, which is not a
     decision made here: CompletedRoom.tsx already threw away a spine and a
     table because both "made a few thousand finished shows into rows of
     text, when the covers ARE the record". The room is a year index beside
     a wall of covers and a card previews its room. */
  const completedCard = (
    <CompletedBoard
      events={completionEvents}
      fallbackCovers={completedCovers}
      archived={archived}
      hours={finishedStats.hours}
      thisYear={finishedStats.thisYear}
      rewatched={finishedStats.rewatched}
      since={counts.since ?? null}
      onOpenRoom={() => go("/list/completed")}
    />
  );

  /* The order, folded into Planned. On a phone the order is not a third
     standing block: it is part of what "planned" means, so it lives inside
     the card rather than beside it. This is what the confirmed phone tree
     always said; the build made it a sibling and it read as a third box. */
  const orderInline = orderRows.length > 0 && (
    <div className="nm-card__order">
      <button
        type="button"
        className="nm-card__orderhead"
        onClick={() => go("/list/plan/order")}
      >
        <span>{isNumbered ? "My order" : "Planned next"}</span>
        <Icon icon={ChevronRight} size={14} className="nm-card__ordergo" />
      </button>
      {/* The one action the standing panel had that the folded version did
          not. Folding the order in without it would have quietly deleted the
          way to start the next thing. */}
      <button
        type="button"
        className="nm-card__orderseal"
        onClick={() => void updateStatus(orderRows[0].id, "watching")}
        aria-label={`Start watching ${orderRows[0].title}`}
      >
        <Icon icon={Play} size={13} />
      </button>
      {orderRows.map((r) => (
        <button
          type="button"
          className="nm-order__row"
          key={r.id}
          onClick={() => go(`/anime/${r.id}`)}
        >
          <span className="nm-order__n">{r.n}</span>
          <NmArt src={r.cover} className="nm-order__cov" />
          <span className="nm-order__tt">{r.title}</span>
        </button>
      ))}
    </div>
  );

  /* Unlike Completed, this card is NOT one big button. It has to hold the
     order's own controls on a phone, and a card whose whole face is a
     button has nowhere to put a second control — the same trap the watching
     strip fell into. Its header is the door instead, the way the watching
     block's header is. */
  const plannedCard = (
    <div className="nm-card nm-card--planned" data-fx>
      <button
        type="button"
        className="nm-card__head nm-card__head--door"
        onClick={() => go("/list/plan")}
      >
        <span className="nm-card__name">Planned</span>
        <span className="nm-card__n">{counts.planned.toLocaleString()}</span>
        <Icon icon={ChevronRight} size={16} className="nm-card__go" />
      </button>
      <span className="nm-card__meta">
        {counts.backlogHours > 0 ? `${counts.backlogHours.toLocaleString()} hrs backlog` : "nothing queued"}
      </span>
      <span className="nm-card__covers">
        {plannedCovers.map((c, i) => (
          <NmArt key={i} src={c} className="nm-card__cover" />
        ))}
      </span>
      {orderInline}
    </div>
  );

  const seqBand = (
    <div className="nm-seqband">
      <button type="button" className="nm-tile" data-fx onClick={() => go("/airing")}>
        <span className="nm-tile__name">New sequels</span>
        <span className="nm-tile__meta">
          {alerts.length > 0 ? `${alerts.length.toLocaleString()} waiting` : "nothing new"}
        </span>
      </button>
      <button type="button" className="nm-tile" data-fx onClick={() => go("/airing")}>
        <span className="nm-tile__name">Airing now</span>
        <span className="nm-tile__meta">
          {counts.airing > 0 ? `${counts.airing.toLocaleString()} in flight` : "nothing airing"}
        </span>
      </button>
    </div>
  );

  return (
    <div className="nm konsou-scroll" ref={rootRef}>
      <div className="nm__stage" ref={stageRef}>
        {/* ── THE ROOM ────────────────────────────────────────────
            Three layers that used to live inside Tonight and now belong to
            the page. Tonight is the only surface here without a plate of its
            own, so these show straight through it and nowhere else: every
            other block paints an opaque ground and hides them.

              0  the wash   the show's art, cast behind the top of the page
              1  the lamp   the pointer light, moved by transform
              2  the grain  the dot grid, the room's own material

            The wash and the lamp belong to whatever you are watching and stop
            partway down. The grain does not belong to any show, so it runs the
            whole height and never fades. */}
        <div className="nm__room" aria-hidden>
          {subjectCover ? (
            <div
              className="nm__wash"
              style={
                {
                  "--nm-bg-art": `url("${sanitizeCssUrl(subjectCover)}")`,
                  ...(subjectLight ? { "--nm-subject-light": subjectLight } : null),
                } as CSSProperties
              }
            />
          ) : null}
          <div className="nm__lamp" ref={lampRef} />
          <div className="nm__grain" />
        </div>
        {/* The census line and search share one row. The field takes the
            line's place rather than pushing it down, so nothing below
            moves when search opens or closes. */}
        <div className="nm-top">
          {searchOpen ? (
            <div className="nm-find">
              <input
                ref={searchRef}
                className="nm-find__input"
                type="search"
                inputMode="search"
                placeholder="Have you seen it?"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Escape") closeSearch();
                }}
                aria-label="Search your whole list"
              />
              <button
                type="button"
                className="nm-find__close"
                onClick={closeSearch}
                aria-label="Close search"
              >
                ✕
              </button>
            </div>
          ) : (
            <>
              <p className="nm-census">{census}</p>
              <button
                type="button"
                className="nm-top__find"
                onClick={() => setSearchOpen(true)}
                aria-label="Search your whole list"
              >
                Search
              </button>
            </>
          )}
        </div>

        {/* Results hang off the field as an overlay: the page stays where
            it was, so closing search returns you to the page you never
            left. Announced too, since a panel appearing below a field is
            not something a screen reader notices on its own. */}
        <p className="nm-sr" role="status">
          {searchOpen && searching
            ? matches.length > 0
              ? `${matches.length} ${matches.length === 1 ? "match" : "matches"} for ${debounced.trim()}`
              : `No matches for ${debounced.trim()}`
            : ""}
        </p>
        {searchOpen && searching && (
          /* No data-fx: §5a scopes the cursor mechanism to cards, Tonight,
             the strip and the order rail. An overlay is not one of them,
             and round 13 already pulled this effect back off controls once
             as scope creep. */
          <div className="nm-results">
            {matches.length > 0 ? (
              <>
                <p className="nm-results__count">
                  {matches.length}
                  {matches.length >= FIND_LIMIT ? "+" : ""}{" "}
                  {matches.length === 1 ? "match" : "matches"}
                </p>
                {matches.map((g) => (
                  <button
                    type="button"
                    className="nm-results__row"
                    key={g.rootId}
                    onClick={() => {
                      go(`/anime/${g.displayEntry.anilist_id}`);
                      closeSearch();
                    }}
                  >
                    <NmArt src={g.displayEntry.cover_url} className="nm-results__cov" />
                    <span className="nm-results__tt">{titleOf(g, titleLanguage)}</span>
                    <span className="nm-results__status">
                      {STATUS_WORD[g.displayEntry.status] ?? g.displayEntry.status}
                    </span>
                  </button>
                ))}
              </>
            ) : (
              /* The likeliest reason it is not here is that it was never
                 added. Finish the thought instead of dead-ending. */
              <div className="nm-results__none">
                <p>Nothing in your list matches “{debounced.trim()}”.</p>
                <button
                  type="button"
                  className="nm-act"
                  onClick={() => {
                    navigate("/discover", {
                      replace: true,
                      state: { fromSearchIntent: true, query: debounced.trim() },
                    });
                  }}
                >
                  Search all anime
                </button>
              </div>
            )}
          </div>
        )}

        {/* ── Tonight ─────────────────────────────────────────────
            The one open stall: highlight border, the only unprompted
            glow, and the only committing action filled in signage. */}
        {!subject && (
          /* Nothing running and nothing queued. The page still needs its
             subject, so the subject becomes the invitation rather than
             vanishing and leaving the surface to open on a register. What it
             offers is whatever is actually available: a sequel that has turned
             up on something you finished beats a cold search. */
          <div className="nm-tonight nm-tonight--none" data-fx>
            <div className="nm-tonight__none">
              <p className="nm-tonight__title">
                {alerts.length > 0 ? "Nothing running, but something arrived" : "Nothing running"}
              </p>
              <p className="nme-3__meta">
                {alerts.length > 0
                  ? `${alerts.length.toLocaleString()} ${alerts.length === 1 ? "sequel is" : "sequels are"} waiting on titles you have finished`
                  : counts.tracked > 0
                    ? "Your record is here. Start something and it takes this spot."
                    : "Start something and it takes this spot."}
              </p>
              <button
                type="button"
                className="nm-act"
                onClick={() => go(alerts.length > 0 ? "/airing" : "/discover")}
                style={{ marginTop: 12, width: "fit-content" }}
              >
                {alerts.length > 0 ? "See what arrived" : "Find something to watch"}
              </button>
            </div>
          </div>
        )}

        {subject && (
          <div className="nm-tonight nmv-3 nmb-1 nmd-1">
            {/* The in-card cast is gone: the page carries the art now, and
                painting it twice would be the same image stacked on itself.
                The grain stays for phone widths only, where Tonight is still
                a plate with the art full-bleed inside it. */}
            <div className="nmb-1__grain" aria-hidden />
            <div className="nmb-1__frame">
              <button
                type="button"
                className="nmb-1__art"
                onClick={subject.onOpen}
                aria-label={`Open ${subject.title}`}
              >
                {subjectCover ? (
                  <img
                    src={subjectCover}
                    alt=""
                    loading="eager"
                    decoding="async"
                    onError={(e) => {
                      const fallback = getCoverUrl({ medium: subject.cover ?? undefined });
                      if (e.currentTarget.src !== fallback) e.currentTarget.src = fallback;
                    }}
                  />
                ) : null}
              </button>
              <div className="nmb-1__scrim" />
            </div>
            <div className="nmb-1__body nmb-1__body--head nmb-1__body--tight nme-3">
              <div className="nm-tonight__head">
              <p className="nm-tonight__title" data-step={titleStep(subject.title)}>
                {subject.title}
              </p>
              <p className="nme-3__meta">
                {subject.state} · Ep <b>{subject.watched}</b> / {subject.total ?? "?"}
                {/* The note is the only thing that says WHY the plate is
                    dormant ("no new episode yet"), and it used to reach the
                    aria-label alone — a screen reader was told more than a
                    sighted reader. It trails the count as its own clause,
                    left in natural case so an explanation reads as prose
                    next to the tracked mono label. Dropped when it would
                    only repeat the state word already leading the line. */}
                {subject.note && subject.note.toLowerCase() !== subject.state.toLowerCase() ? (
                  <span className="nme-3__note"> · {subject.note}</span>
                ) : null}
              </p>
              </div>
              {/* THE RECORD. Ten pips scaled to a percentage said the same
                  thing a bar says, only coarser. These are the actual
                  episodes: one cell each, filled for what you have watched,
                  lit for the one the button will log, outlined for what has
                  aired and is waiting, and faint for what has not aired yet.
                  Past the cap a show has too many episodes for one cell each
                  to be legible, so it falls back to the bar. */}
              {subject.total != null && subject.total > 0 && subject.total <= EPISODE_CELL_CAP ? (
                <div
                  className="nm-cells"
                  role="img"
                  aria-label={`${subject.watched} of ${subject.total} episodes watched${
                    subject.aired != null && subject.aired > subject.watched
                      ? `, ${subject.aired - subject.watched} aired and waiting`
                      : ""
                  }`}
                >
                  {Array.from({ length: subject.total }, (_, i) => {
                    const watched = i < subject.watched;
                    const isNext = i === subject.watched;
                    const airedYet = subject.aired == null || i < subject.aired;
                    return (
                      <span
                        key={i}
                        className="nm-cells__cell"
                        data-state={
                          watched ? "done" : isNext && airedYet ? "next" : airedYet ? "waiting" : "unaired"
                        }
                      />
                    );
                  })}
                </div>
              ) : (
                <div className="nm-cells nm-cells--bar" aria-hidden>
                  <i style={{ width: `${subject.percent ?? 0}%` }} />
                </div>
              )}

              {/* THE THREAD. What else of this franchise you keep, and where
                  each one stands. */}
              {subject.thread && (
                <ul className="nm-thread">
                  {subject.thread.map((m) => (
                    <li key={m.id}>
                      <button
                        type="button"
                        className="nm-thread__item"
                        data-current={m.current || undefined}
                        onClick={() => go(`/anime/${m.id}`)}
                      >
                        <span className="nm-thread__name">{m.title}</span>
                        <span className="nm-thread__state" style={{ color: statusMeta(m.status).color }}>
                          {m.status === "completed"
                            ? "done"
                            : m.total
                              ? `${m.watched} / ${m.total}`
                              : statusMeta(m.status).label.toLowerCase()}
                        </span>
                      </button>
                    </li>
                  ))}
                </ul>
              )}
              <button
                type="button"
                className="nm-act"
                onClick={subject.onAct}
                disabled={subject.disabled}
                aria-label={subject.actionHint}
                style={{ marginTop: 10, width: "fit-content" }}
              >
                {subject.actionLabel}
              </button>
            </div>
          </div>
        )}

        {/* ── The drawer ──────────────────────────────────────────
            Everything else running, hanging off the bottom of Tonight
            rather than plated beside it. The guard is the TAIL, not the
            total: with exactly one watching title that title IS Tonight,
            so the tail is empty, and the old `|| counts.watchingTitles > 0`
            drew a bordered block around an empty carousel. Nothing renders
            around nothing now. */}
        {stripGroups.length > 0 && (
          <WatchDrawer
            groups={stripGroups}
            count={counts.watchingTitles}
            onOpenRoom={() => go("/list/watching")}
            onOpen={(id) => go(`/anime/${id}`)}
          />
        )}

        {/* ── The anchors ─────────────────────────────────────────
            Desktop and medium: a backdrop familying both, with the
            order beside it (medium drops the order underneath). Phone:
            no backdrop at all — Planned stands in place and Completed
            reduces to a door. */}
        {isPhone ? (
          <>
            {counts.planned > 0 ? (
              <>
                {plannedCard}
                <button
                  type="button"
                  className="nm-cdoor"
                  data-fx
                  onClick={() => go("/list/completed")}
                >
                  <span className="nm-cdoor__name">Completed</span>
                  <span className="nm-cdoor__n">{archived.toLocaleString()}</span>
                  <Icon icon={ChevronRight} size={16} className="nm-cdoor__go" />
                </button>
              </>
            ) : (
              /* Nothing planned, so there is nothing to sit small beside:
                 Completed expands into the slot instead of staying a door. */
              completedCard
            )}
          </>
        ) : (
          /* The order used to stand here as a third block below these two.
             It is folded into Planned now, at every width, the way the phone
             tree always had it: the order is part of what "planned" means,
             not a peer of it. This also retires .nm-row2 and .nm-main, which
             wrapped nothing once the third child left, and .nm-row2--stacked,
             which never applied at all because .nm-row2 was never a flex
             container, so the side-by-side layout it described never ran. */
          <>
            <div className="nm-backdrop">
              <div className="nm-bd__row">
                {completedCard}
                {plannedCard}
              </div>
            </div>
            {seqBand}
          </>
        )}
        {/* On a phone the band follows the anchors in the single column. */}
        {isPhone && seqBand}

      </div>
    </div>
  );
}
