import { useEffect, useMemo, useRef, useState } from "react";
import type { CSSProperties, ReactNode, UIEvent } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  ChevronLeft,
  ChevronRight,
  Copy,
  Globe,
  Info,
  Loader2,
  NotebookPen,
  Play,
  Plus,
  Share2,
  Star,
  Tv,
} from "lucide-react";
import { AnimeCover, hueFromTitle } from "@/components/anime/AnimeCover";
import { QuickMenu } from "@/components/anime/QuickMenu";
import { EpisodeCounter } from "@/components/anime/EpisodeCounter";
import { formatChipMeta, relationChipMeta } from "@/components/anime/relationMeta";
import { statusMeta } from "@/components/anime/statusMeta";
import { StatusSheet } from "@/components/anime/StatusSheet";
import { SpineRail, spineStateForStatus } from "@/components/anime/SpineRail";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { Skeleton } from "@/components/ui/Skeleton";
import { Text } from "@/components/ui/Text";
import { useAnimeDetail, useMalScore, useRelationChain } from "@/hooks/useAniList";
import { segmentHashtags } from "@/lib/hashtags";
import { computeFranchiseLedger, ledgerEpisodeLabel } from "@/lib/franchise/ledger";
import { isFranchiseOther } from "@/lib/franchise/relatedness";
import { isPromoNode, mainStoryIds } from "@/lib/franchise/storySplit";
import { orderByRelease } from "@/lib/franchise/watchOrder";
import type { RelationEdge } from "@/lib/franchise/watchOrder";
import type { RelationChainResult } from "@/lib/franchise/chain";
import { goBack } from "@/hooks/useAppBack";
import { useDragScroll } from "@/hooks/useDragScroll";
import {
  airedEpisodes,
  airingStatusLabel,
  alternateTitles,
  formatFuzzyDate,
  formatLabel,
  formatScore,
  getCoverUrl,
  isMangaNode,
  preferredTitle,
  seasonYearLabel,
  stripHtml,
} from "@/lib/format";
import { openExternal } from "@/lib/openExternal";
import { getDisabledStatuses } from "@/lib/statusValidation";
import { toast } from "@/lib/store/toastStore";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type {
  AnimeMedia,
  AnimeTitle,
  AniListMediaStatus,
  CoverImage,
  ExternalLink,
  FuzzyDate,
  MediaFormat,
  MediaSeason,
  NextAiringEpisode,
  RelationNode,
  RelationType,
} from "@/types/anime";
import type { AnimeListEntry, ListEntryPatch, ListStatus, TitleLanguage } from "@/types/list";

type DetailTab = "overview" | "cast" | "related" | "similar";

const SEASON_RELATIONS: RelationType[] = [
  "PREQUEL",
  "SEQUEL",
  "SIDE_STORY",
  "SPIN_OFF",
  "PARENT",
  "ALTERNATIVE",
];

const DUB_SITE_HINTS = [
  "crunchyroll",
  "hidive",
  "netflix",
  "hulu",
  "disney",
  "prime video",
  "funimation",
];

interface SeasonRow {
  id: number;
  title: AnimeTitle;
  coverImage?: CoverImage | null;
  relationType?: RelationType | "CURRENT";
  format?: MediaFormat | null;
  status?: AniListMediaStatus | null;
  startDate?: FuzzyDate | null;
  season?: MediaSeason | null;
  seasonYear?: number | null;
  nextAiringEpisode?: NextAiringEpisode | null;
  episodes?: number | null;
  /** Direct relation of the viewed title; its relationType label is
   *  meaningful. Chain nodes found deeper carry their parent's label. */
  direct?: boolean;
}

function externalTypeLabel(type?: string | null): string | null {
  if (!type) return null;
  return type.replace(/_/g, " ").toLowerCase();
}

/** True if a link provides an English dub. Checks explicit language first,
 *  then falls back to site-name heuristic for links without language metadata. */
function isDubLink(link: ExternalLink): boolean {
  if (link.language) return link.language.toLowerCase().includes("english");
  const site = link.site.toLowerCase();
  return DUB_SITE_HINTS.some((hint) => site.includes(hint));
}

function isStreamingLink(link: ExternalLink): boolean {
  return !link.isDisabled && (!link.type || link.type === "STREAMING");
}

function externalLinkMeta(link: ExternalLink): string[] {
  const meta: string[] = [];
  if (link.language) meta.push(link.language);
  const type = externalTypeLabel(link.type);
  if (type && type !== "streaming") meta.push(type);
  if (link.notes) meta.push(link.notes);
  return meta;
}

interface SeasonRowsResult {
  rows: SeasonRow[];
  /** Ids on the SEQUEL/PREQUEL backbone — the numbered "main story" section.
   *  Everything else renders under Extras with a placement label. */
  mainIds: Set<number>;
}

function getSeasonRows(
  media: AnimeMedia,
  chain?: RelationChainResult,
): SeasonRowsResult {
  const byId = new Map<number, SeasonRow>();
  byId.set(media.id, {
    id: media.id,
    title: media.title,
    coverImage: media.coverImage,
    relationType: "CURRENT",
    format: media.format,
    status: media.status,
    startDate: media.startDate,
    season: media.season,
    seasonYear: media.seasonYear,
    nextAiringEpisode: media.nextAiringEpisode,
    episodes: media.episodes,
    direct: true,
  });

  const add = (r: RelationNode, direct: boolean) => {
    if (byId.has(r.id)) return;
    byId.set(r.id, {
      id: r.id,
      title: r.title,
      coverImage: r.coverImage,
      relationType: r.relationType,
      format: r.format,
      status: r.status,
      startDate: r.startDate,
      season: r.season,
      seasonYear: r.seasonYear,
      nextAiringEpisode: r.nextAiringEpisode,
      episodes: r.episodes,
      direct,
    });
  };

  // Manga/novel relations (ALTERNATIVE source versions etc.) aren't openable
  // as anime; the detail query would 404. isMangaNode also catches pre-`type`
  // cached snapshots via their format ("Edgerunners MADNESS").
  // OTHER edges count too when the names claim the same franchise — some
  // direct continuations (Edgerunners 2) are linked ONLY that way.
  for (const r of media.relations ?? []) {
    if (isMangaNode(r)) continue;
    // Same junk gate as the deep walk: music videos and promo shorts are
    // advertising, not members — without this, direct relations leak them
    // in even though the walk refuses them.
    if (r.format === "MUSIC" || isPromoNode(r)) continue;
    if (
      SEASON_RELATIONS.includes(r.relationType) ||
      isFranchiseOther(media.title, r)
    ) {
      add(r, true);
    }
  }
  // The rest of the franchise, walked breadth-first (lib/franchise/chain):
  // entries only reachable through other seasons, so season 1 still lists
  // season 3, the movies, everything.
  for (const r of chain?.nodes ?? []) add(r, false);

  // Release order is the honest default (watch order is a curated community
  // call with no source of truth). The relation edges are still needed to tell
  // main story from extras, they just no longer decide the sequence.
  const edges: RelationEdge[] =
    chain?.edges ??
    (media.relations ?? [])
      .filter((r) => !isMangaNode(r))
      .map((r) => ({ from: media.id, to: r.id, type: r.relationType }));
  const position = new Map(
    orderByRelease([...byId.values()]).map((id, i) => [id, i]),
  );

  const rows = [...byId.values()].sort(
    (a, b) => (position.get(a.id) ?? 0) - (position.get(b.id) ?? 0),
  );
  return { rows, mainIds: mainStoryIds(rows, edges) };
}

function seasonLabel(row: SeasonRow): string {
  // Year lives on the left rail now, so it's dropped from this meta line.
  const bits = [
    formatLabel(row.format),
    airingStatusLabel(row.status),
    row.episodes ? `${row.episodes} eps` : null,
  ].filter(Boolean);
  return bits.join(" · ");
}

function formatCountdown(seconds: number): string {
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  if (d > 0) return `${d}d ${h}h`;
  const m = Math.floor((seconds % 3600) / 60);
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
}

interface ReleaseFact {
  label: string;
  value: string;
  accent?: boolean;
}

/** Facts the header does NOT already state. Status, episode count, season,
 *  and studio all live in the hero (meta line + status row); repeating them
 *  down here just pushed the rest of the page further away. */
function releaseFacts(
  media: AnimeMedia,
  malScore?: number | null,
): ReleaseFact[] {
  const source = media.source
    ? media.source.replace(/_/g, " ").toLowerCase()
    : null;
  const facts = [
    // The MAL community score answers "is this any good" without leaving the
    // page. Jikan-sourced; silently absent when MAL doesn't know the title.
    {
      label: "MAL score",
      value: malScore != null ? malScore.toFixed(2) : null,
    },
    { label: "First aired", value: formatFuzzyDate(media.startDate) },
    {
      label: "Episode length",
      value: media.duration ? `${media.duration} min` : null,
    },
    {
      label: "Source",
      value: source ? source.charAt(0).toUpperCase() + source.slice(1) : null,
    },
  ].filter((f): f is ReleaseFact => Boolean(f.value));
  if (media.nextAiringEpisode) {
    facts.unshift({
      label: "Next episode",
      value: `EP ${media.nextAiringEpisode.episode} in ${formatCountdown(
        media.nextAiringEpisode.timeUntilAiring,
      )}`,
      accent: true,
    });
  }
  return facts;
}

export function AnimeDetail() {
  const { id } = useParams();
  const animeId = id ? Number(id) : null;
  const navigate = useNavigate();
  const { data: media, isLoading, isError, refetch } = useAnimeDetail(animeId);
  const genreRowRef = useDragScroll<HTMLDivElement>();

  const entry = useListStore((s) => (animeId ? s.map[animeId] : undefined));
  // Whole map: the Related tab shows the user's progress on every entry of
  // the franchise, so "what's left to watch" is readable at a glance.
  const listMap = useListStore((s) => s.map);
  const addFromSummary = useListStore((s) => s.addFromSummary);
  const regroupFranchise = useListStore((s) => s.regroupFranchise);
  const updateStatus = useListStore((s) => s.updateStatus);
  const setDubStatus = useListStore((s) => s.setDubStatus);
  const incrementEpisodes = useListStore((s) => s.incrementEpisodes);
  const patchEntry = useListStore((s) => s.patch);
  const remove = useListStore((s) => s.remove);

  const [statusOpen, setStatusOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  const [namesOpen, setNamesOpen] = useState(false);
  const [synopsisOpen, setSynopsisOpen] = useState(false);

  // Navigating within the detail page (Related row -> another season) keeps
  // this component mounted; an open names panel would leak onto the next
  // title's header.
  useEffect(() => {
    setNamesOpen(false);
  }, [animeId]);
  const [topbarSolid, setTopbarSolid] = useState(false);
  const [tab, setTab] = useState<DetailTab>("overview");
  const bannerRef = useRef<HTMLDivElement>(null);

  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const title = media ? preferredTitle(media.title, titleLanguage) : "";
  // One name on screen; every other handle (other-language titles + AniList
  // synonyms) lives behind the small info toggle next to the title.
  const alternates = media ? alternateTitles(media.title, titleLanguage) : [];
  const synonyms = media?.synonyms?.filter((s) => s.trim()) ?? [];
  const otherNames: string[] = [];
  {
    const seen = new Set<string>([title]);
    for (const n of [...alternates, ...synonyms]) {
      const v = n.trim();
      if (v && !seen.has(v)) {
        seen.add(v);
        otherNames.push(v);
      }
    }
  }
  const inList = !!entry;

  const metaBits = media
    ? [
        formatLabel(media.format),
        media.episodes ? `${media.episodes} eps` : null,
        seasonYearLabel(media),
        media.studio,
      ].filter(Boolean)
    : [];

  const { data: chain, isFetching: chainLoading } = useRelationChain(media);
  const { data: malScore } = useMalScore(media?.idMal);
  const { rows: seasonRows, mainIds } = useMemo(
    () =>
      media
        ? getSeasonRows(media, chain)
        : { rows: [] as SeasonRow[], mainIds: new Set<number>() },
    [media, chain],
  );
  // (The story backbone used to be kept as its own list purely to anchor the
  // "after #N" placement labels. Those are gone; mainIds alone still decides
  // which rows carry a number.)
  // The current title is the hero of this page; don't list it again under
  // "Related Series". Only the other seasons/entries belong there.
  const relatedRows = useMemo(
    () => seasonRows.filter((r) => r.id !== media?.id),
    [seasonRows, media],
  );
  // Completion ledger over everything the chain walker found, current title
  // included: how much of this series exists vs how much has been seen.
  // ALTERNATIVE tellings stay visible in the Related list but sit outside the
  // completion math — the quick menu's ledger never counts them, and both
  // surfaces must report the same percentage for the same franchise.
  const seriesLedger = useMemo(
    () =>
      computeFranchiseLedger(
        seasonRows
          .filter((r) => r.relationType !== "ALTERNATIVE")
          .map((r) => ({ episodes: r.episodes, entry: listMap[r.id] })),
      ),
    [seasonRows, listMap],
  );
  const streamingLinks = useMemo(
    () => (media?.externalLinks ?? []).filter(isStreamingLink),
    [media],
  );
  const dubLinks = useMemo(
    () => streamingLinks.filter(isDubLink),
    [streamingLinks],
  );

  // Persist dub status to the list entry so cards can show it without loading detail.
  useEffect(() => {
    if (animeId != null && entry && media) {
      void setDubStatus(animeId, dubLinks.length > 0);
    }
  }, [animeId, entry, media, dubLinks.length, setDubStatus]);

  // Backfill time accounting from the fresh detail payload: per-episode
  // duration, missing totals (crediting completed entries that predate the
  // number), and the aired count. Value-guarded so it settles in one pass.
  useEffect(() => {
    if (animeId == null || !entry || !media) return;
    const p: ListEntryPatch = {};
    if (media.duration != null && entry.episode_duration !== media.duration) {
      p.episode_duration = media.duration;
    }
    if (entry.total_episodes == null && media.episodes != null) {
      p.total_episodes = media.episodes;
      // A completed entry with no known total was credited zero episodes;
      // completion means the whole run was seen.
      if (
        entry.status === "completed" &&
        entry.episodes_watched < media.episodes
      ) {
        p.episodes_watched = media.episodes;
      }
    }
    const aired = airedEpisodes(media);
    if (aired != null && entry.aired_episodes !== aired) {
      p.aired_episodes = aired;
    }
    if (Object.keys(p).length > 0) void patchEntry(animeId, p);
  }, [animeId, entry, media, patchEntry]);
  const facts = media ? releaseFacts(media, malScore) : [];

  const onScroll = (e: UIEvent<HTMLDivElement>) => {
    const y = e.currentTarget.scrollTop;
    if (bannerRef.current) {
      bannerRef.current.style.transform = `translateY(${y * 0.4}px)`;
    }
    const solid = y > 200;
    setTopbarSolid((prev) => (prev !== solid ? solid : prev));
  };

  const share = async () => {
    if (!animeId) return;
    const url = `https://anilist.co/anime/${animeId}`;
    try {
      await navigator.clipboard.writeText(url);
      toast.success("Link copied");
    } catch {
      void openExternal(url);
    }
  };

  const copyTitle = async () => {
    try {
      await navigator.clipboard.writeText(title);
      toast.success("Title copied");
    } catch {
      toast.error("Couldn't copy the title");
    }
  };

  const searchGoogle = () =>
    void openExternal(
      `https://www.google.com/search?q=${encodeURIComponent(`${title} anime`)}`,
    );

  if (isLoading) return <DetailSkeleton onBack={goBack} />;
  if (isError || !media) {
    // Offline-first: a tracked title never dead-ends. Everything the list
    // entry knows (cover, title, status, progress, score) renders from local
    // data; only the AniList-enriched sections need the network.
    if (entry) {
      const savedTitle = preferredTitle(
        {
          romaji: entry.title_romaji,
          english: entry.title_english,
          native: entry.title_native,
        },
        titleLanguage,
      );
      const meta = statusMeta(entry.status);
      const canIncrement =
        entry.status === "watching" || entry.status === "rewatching";
      return (
        <div className="k-page">
          <DetailTopBar solid title={savedTitle} onBack={goBack} onShare={share} />
          <div className="k-offdetail konsou-scroll">
            <div className="k-offdetail__card">
              <div className="k-offdetail__cover">
                <AnimeCover src={entry.cover_url ?? undefined} alt={savedTitle} />
              </div>
              <div className="k-offdetail__body">
                <Text as="h1" size="lg" weight={700} clamp={2}>
                  {savedTitle}
                </Text>
                <span className="k-pill">
                  <span className="k-pill__icon" style={{ color: meta.color }}>
                    <Icon icon={meta.icon} size={12} weight="fill" />
                  </span>
                  {meta.label}
                </span>
                <Text size="sm" color="secondary">
                  {entry.episodes_watched} / {entry.total_episodes ?? "?"} episodes
                  {entry.score != null ? ` · ★ ${formatScore(entry.score)}` : ""}
                </Text>
                {canIncrement && (
                  <Button
                    size="sm"
                    variant="secondary"
                    onClick={() => void incrementEpisodes(entry.anilist_id, 1)}
                  >
                    +1 episode
                  </Button>
                )}
              </div>
            </div>
            <Text size="sm" color="tertiary" className="k-offdetail__note">
              Konsou can't reach AniList right now, so this is your saved copy.
              Progress changes still work and sync later.
            </Text>
            <Button variant="primary" onClick={() => void refetch()}>
              Try again
            </Button>
          </div>
        </div>
      );
    }
    return (
      <div className="k-page">
        <DetailTopBar solid onBack={goBack} onShare={share} />
        <EmptyState
          title="Couldn't load details"
          subtitle="Konsou can't reach AniList right now."
          action={
            <Button size="sm" variant="primary" onClick={() => void refetch()}>
              Try again
            </Button>
          }
        />
      </div>
    );
  }

  const onPickStatus = (status: ListStatus) => {
    if (inList) void updateStatus(animeId!, status);
    else void addFromSummary(media, status);
  };

  const synopsis = stripHtml(media.description);

  return (
    <div className="k-page k-detail">
      <DetailTopBar
        solid={topbarSolid}
        title={topbarSolid ? title : undefined}
        onBack={goBack}
        onShare={share}
      />

      <div className="k-detail__scroll konsou-scroll" onScroll={onScroll}>
        <div className="k-detail__hero">
          <div className="k-detail__banner" ref={bannerRef}>
            {/* Many titles have no banner art. Fall back to the cover, blurred
                into an ambient backdrop; with no art at all, the title's own
                identity hue (same one the cover tile uses) fills the hero. */}
            {media.bannerImage ? (
              <img src={media.bannerImage} alt="" role="presentation" />
            ) : getCoverUrl(media.coverImage) ? (
              <img
                src={getCoverUrl(media.coverImage)}
                alt=""
                role="presentation"
                className="k-detail__banner-blur"
              />
            ) : (
              <div
                className="k-detail__banner-tint"
                style={{
                  background: `linear-gradient(160deg, oklch(30% 0.06 ${hueFromTitle(title)}), oklch(14% 0.03 ${(hueFromTitle(title) + 50) % 360}))`,
                }}
              />
            )}
          </div>
          <div className="k-detail__heroscrim" />
        </div>

        <div className="k-detail__headrow">
          <div className="k-detail__cover">
            <AnimeCover src={getCoverUrl(media.coverImage)} alt={title} />
          </div>
          <div className="k-detail__headinfo">
            <div className="k-detail__titlerow">
              <Text as="h1" size="2xl" weight={700} clamp={3}>
                {title}
              </Text>
              {otherNames.length > 0 && (
                <button
                  type="button"
                  className="k-detail__namesbtn"
                  onClick={() => setNamesOpen((v) => !v)}
                  aria-expanded={namesOpen}
                  aria-label={`Other names (${otherNames.length})`}
                  title={otherNames.join("\n")}
                >
                  <Icon icon={Info} size={14} />
                </button>
              )}
            </div>
            {namesOpen && otherNames.length > 0 && (
              <ul className="k-detail__names">
                {otherNames.map((n) => (
                  <li key={n}>{n}</li>
                ))}
              </ul>
            )}
            <Text size="sm" color="secondary" className="k-detail__meta">
              {metaBits.join(" · ")}
            </Text>
            <div className="k-detail__langrow">
              {streamingLinks.length > 0 && (
                <>
                  {dubLinks.length > 0 ? (
                    <span className="k-langbadge k-langbadge--dub">DUB+SUB</span>
                  ) : (
                    <span className="k-langbadge k-langbadge--sub">SUB</span>
                  )}
                </>
              )}
              {media.status && (
                <Text size="xs" color="tertiary">
                  {airingStatusLabel(media.status)}
                </Text>
              )}
            </div>
            <div className="k-detail__titleactions">
              <button type="button" onClick={() => void copyTitle()}>
                <Icon icon={Copy} size={13} />
                Copy title
              </button>
              <button type="button" onClick={searchGoogle}>
                <Icon icon={Globe} size={13} />
                Google
              </button>
            </div>
          </div>
        </div>

        <div className="k-detail__body">
          {/* User controls */}
          {entry ? (
            /* One panel for your relationship to this title: state, score,
               progress, tags and note together, instead of three unrelated
               controls that each opened a different sheet. */
            <div className="k-track">
              <button
                type="button"
                className="k-track__top"
                onClick={() => setEditOpen(true)}
                aria-label="Edit status, score, tags and notes"
              >
                <span
                  className="k-track__status"
                  style={{ color: statusMeta(entry.status).color }}
                >
                  <Icon icon={statusMeta(entry.status).icon} size={16} weight="fill" />
                  {statusMeta(entry.status).label}
                </span>
                <span className="k-track__score">
                  <Icon
                    icon={Star}
                    size={15}
                    weight={entry.score != null ? "fill" : "regular"}
                    color="var(--color-warning)"
                  />
                  {formatScore(entry.score)}
                </span>
                <Icon icon={ChevronRight} size={16} className="k-track__chev" />
              </button>

              {/* Logging stays inline: it is the frequent act, and making it
                  cost a sheet would be a step backwards. The reached-finale
                  prompt lives in listStore.setEpisodes, so it fires here too. */}
              <div className="k-track__progress">
                <EpisodeCounter
                  anilistId={animeId!}
                  watched={entry.episodes_watched}
                  total={entry.total_episodes}
                />
              </div>

              <button
                type="button"
                className={`k-track__note${entry.notes ? "" : " k-track__note--empty"}`}
                onClick={() => setEditOpen(true)}
                aria-label={entry.notes ? "Edit your note" : "Add a note"}
              >
                <Icon icon={NotebookPen} size={15} />
                <span className="k-track__notetext">
                  {entry.notes
                    ? segmentHashtags(entry.notes).map((seg, i) =>
                        seg.tag ? (
                          <span key={i} className="k-track__tag">
                            {seg.text}
                          </span>
                        ) : (
                          <span key={i}>{seg.text}</span>
                        ),
                      )
                    : "Add a private note. Use #tags to group titles across your list."}
                </span>
              </button>
            </div>
          ) : (
            <Button
              variant="primary"
              size="lg"
              block
              onClick={() => setStatusOpen(true)}
            >
              <Icon icon={Plus} size={20} /> Add to List
            </Button>
          )}

          {/* Wiki-style tabs: judge the show without leaving the app. */}
          <div className="k-subtabs k-detail__tabs" role="tablist">
            {(
              [
                ["overview", "Overview"],
                ["cast", "Cast"],
                ...(relatedRows.length > 0 ? [["related", "Related"]] : []),
                ...((media.recommendations?.length ?? 0) > 0
                  ? [["similar", "Similar"]]
                  : []),
              ] as [DetailTab, string][]
            ).map(([id, label]) => (
              <button
                key={id}
                role="tab"
                aria-selected={tab === id}
                className={`k-subtab${tab === id ? " k-subtab--active" : ""}`}
                onClick={() => setTab(id)}
              >
                {label}
              </button>
            ))}
          </div>

          {/* Keyed by tab: switching remounts the panel with a short rise-in,
              so the change reads as content arriving, not a hard swap. */}
          <div key={tab} className="k-detail__tabpanel">
          {tab === "overview" && (
            <>
              {/* Wiki order: identity first (genres), then what it is
                  (synopsis), then secondary facts, then where to watch.
                  The facts grid used to open the page and pushed everything
                  the reader actually came for below the fold. */}
              {media.genres && media.genres.length > 0 && (
                <section className="k-detail__section">
                  <div ref={genreRowRef} className="k-chiprow k-chiprow--scroll">
                    {media.genres.map((g) => (
                      <span key={g} className="k-genre">
                        {g}
                      </span>
                    ))}
                  </div>
                </section>
              )}

              {/* Synopsis */}
              {synopsis && (
                <section className="k-detail__section">
                  <Text
                    size="base"
                    color="secondary"
                    clamp={synopsisOpen ? undefined : 3}
                    style={{ whiteSpace: "pre-line" }}
                  >
                    {synopsis}
                  </Text>
                  <button
                    type="button"
                    className="k-detail__showmore"
                    onClick={() => setSynopsisOpen((o) => !o)}
                  >
                    {synopsisOpen ? "Show less" : "Show more"}
                  </button>
                </section>
              )}

              {facts.length > 0 && (
                <section className="k-detail__section">
                  <Text as="h2" size="lg" weight={600} className="k-detail__sectiontitle">
                    Details
                  </Text>
                  <div className="k-releasegrid">
                    {facts.map((f) => (
                      <div
                        key={f.label}
                        className={f.accent ? "k-releasegrid__hot" : undefined}
                      >
                        <span>{f.label}</span>
                        <strong>{f.value}</strong>
                      </div>
                    ))}
                  </div>
                </section>
              )}

              {streamingLinks.length > 0 && (
                <Section title="Availability">
                  <div className="k-availabilitygrid">
                    {streamingLinks.slice(0, 8).map((l) => {
                      const meta = externalLinkMeta(l);
                      const dub = isDubLink(l);
                      return (
                        <button
                          key={l.url}
                          type="button"
                          className={`k-availability${dub ? " k-availability--dub" : ""}`}
                          onClick={() => void openExternal(l.url)}
                        >
                          <span className="k-availability__top">
                            <Tv size={16} />
                            <span>{l.site}</span>
                          </span>
                          <span className="k-availability__meta">
                            {meta.length > 0 ? meta.join(" · ") : "Streaming"}
                          </span>
                          {dub && <span className="k-availability__dub">Dub source</span>}
                        </button>
                      );
                    })}
                  </div>
                  {dubLinks.length > 0 && (
                    <Text size="xs" color="tertiary">
                      Dub source is inferred from common dub-capable streaming providers.
                    </Text>
                  )}
                </Section>
              )}

              {media.trailer?.site === "youtube" && (
                <Section title="Trailer">
                  <button
                    type="button"
                    className="k-trailer"
                    onClick={() =>
                      void openExternal(
                        `https://www.youtube.com/watch?v=${media.trailer!.id}`,
                      )
                    }
                  >
                    {media.trailer.thumbnail && (
                      <img src={media.trailer.thumbnail} alt="" loading="lazy" />
                    )}
                    <span className="k-trailer__play">
                      <Icon icon={Play} size={22} weight="fill" />
                    </span>
                    <span className="k-trailer__label">Watch on YouTube</span>
                  </button>
                </Section>
              )}
            </>
          )}

          {tab === "cast" && (
            <>
              <CharactersRow media={media} />
              <StaffRow media={media} />
            </>
          )}

          {tab === "related" && relatedRows.length > 0 && (
            <Section title="Where this sits in the series">
              {/* The completionist's ledger: only meaningful once something
                  here is tracked, and only while the chain isn't mid-load
                  (a partial chain would understate what exists). */}
              {seriesLedger.trackedCount > 0 &&
                seriesLedger.memberCount >= 2 &&
                !chainLoading && (
                  <p
                    className={`k-seasonrows__ledger${seriesLedger.fullSet ? " k-seasonrows__ledger--full" : ""}`}
                  >
                    {seriesLedger.fullSet
                      ? `All ${seriesLedger.memberCount} entries on your list · ${ledgerEpisodeLabel(seriesLedger)}`
                      : `${ledgerEpisodeLabel(seriesLedger)} across ${seriesLedger.memberCount} entries · ${seriesLedger.untrackedCount} not on your list`}
                  </p>
                )}
              {(() => {
                // One renderer for both sections: main-story rows get their
                // watch-order number; extras get a dot and a "where it falls"
                // placement chip derived from air dates.
                const renderSeasonRow = (
                  row: SeasonRow,
                  num: number | null,
                  spine: { first: boolean; last: boolean },
                ) => {
                  const rowEntry = listMap[row.id];
                  const isCurrent = row.id === media.id;
                  const relChip = row.direct
                    ? relationChipMeta(row.relationType)
                    : null;
                  const fmtChip = formatChipMeta(row.format);
                  const unaired = row.status === "NOT_YET_RELEASED";
                  const unairedDate = unaired
                    ? formatFuzzyDate(row.startDate)
                    : null;
                  const year = row.seasonYear ?? row.startDate?.year ?? null;
                  const spineState = spineStateForStatus(rowEntry?.status);
                  // Entry point for a newcomer: first season, still unstarted,
                  // and not the one you're already on.
                  const startHere =
                    num === 1 &&
                    !isCurrent &&
                    (spineState === "planned" || spineState === "untracked");
                  const shownTitle = preferredTitle(row.title, titleLanguage);
                  const inner = (
                    <>
                      <SpineRail
                        year={year}
                        state={spineState}
                        variant={num != null ? "main" : "extra"}
                        first={spine.first}
                        last={spine.last}
                      />
                      <span className="k-seasonrow__cover">
                        <AnimeCover
                          src={getCoverUrl(row.coverImage)}
                          alt={preferredTitle(row.title, titleLanguage)}
                        />
                        {num != null && (
                          <span className="k-seasonrow__num" aria-hidden>
                            #{num}
                          </span>
                        )}
                      </span>
                      <div className="k-seasonrow__body">
                        <Text
                          size="base"
                          weight={600}
                          clamp={2}
                          className="k-seasonrow__title"
                        >
                          {shownTitle}
                        </Text>
                        <Text size="xs" color="secondary" clamp={2}>
                          {seasonLabel(row)}
                        </Text>
                        <span className="k-seasonrow__chips">
                          {isCurrent && (
                            <span className="k-seasonrow__type k-seasonrow__type--current">
                              You are here
                            </span>
                          )}
                          {startHere && (
                            <span className="k-seasonrow__type k-seasonrow__type--start">
                              Start here
                            </span>
                          )}
                          {!isCurrent && relChip && (
                            <span className="k-chip-kind">{relChip.label}</span>
                          )}
                          {fmtChip && (
                            <span className="k-chip-kind">{fmtChip.label}</span>
                          )}
                          {/* No "after #2" placement chip. The list is already
                              in order; restating each extra's position against
                              a season number was noise on top of an order you
                              can simply read, and it is the same label the
                              quick menu dropped. */}
                          {unaired && (
                            <span className="k-chip-unaired">
                              {unairedDate
                                ? `Not aired yet · ${unairedDate}`
                                : "Not aired yet · TBA"}
                            </span>
                          )}
                          {rowEntry && <SeasonRowStatus entry={rowEntry} />}
                        </span>
                      </div>
                    </>
                  );
                  return isCurrent ? (
                    // The entry being viewed: loud, unmistakable, not a link.
                    <div
                      key={row.id}
                      className="k-seasonrow k-seasonrow--current"
                      aria-current="true"
                    >
                      {inner}
                    </div>
                  ) : (
                    <button
                      key={row.id}
                      type="button"
                      className={`k-seasonrow${unaired ? " k-seasonrow--unaired" : ""}${rowEntry?.status === "not_interested" ? " k-seasonrow--dimmed" : ""}`}
                      // Tracked rows carry their status as a thin left-edge
                      // bar — same paint language as the quick menu.
                      style={
                        rowEntry
                          ? ({
                              "--card-status": statusMeta(rowEntry.status).color,
                            } as CSSProperties)
                          : undefined
                      }
                      onClick={() => navigate(`/anime/${row.id}`, { replace: true })}
                    >
                      {inner}
                    </button>
                  );
                };
                // One interleaved list in release order, threaded on the spine:
                // seasons carry a running #1..#N and sit on the line, extras
                // branch off where they aired with an "after #N" chip.
                let mainNo = 0;
                return (
                  <div className="k-seasonrows">
                    {seasonRows.map((row, i) => {
                      const spine = {
                        first: i === 0,
                        last: i === seasonRows.length - 1,
                      };
                      if (mainIds.has(row.id)) {
                        mainNo += 1;
                        return renderSeasonRow(row, mainNo, spine);
                      }
                      return renderSeasonRow(row, null, spine);
                    })}
                  </div>
                );
              })()}
              {chainLoading && (
                <Text size="xs" color="tertiary" className="k-seasonrows__loading">
                  Looking for the rest of the series…
                </Text>
              )}
              {/* Self-heal for a franchise the background pass split into
                  separate cards: re-resolve and share one root. Only worth
                  offering when 2+ of these seasons are actually tracked. */}
              {relatedRows.filter((r) => listMap[r.id]).length >= 1 && inList && (
                <button
                  type="button"
                  className="k-btn k-btn--sm k-btn--ghost k-seasonrows__regroup"
                  onClick={() => animeId != null && regroupFranchise(animeId)}
                >
                  Group these on My List
                </button>
              )}
            </Section>
          )}

          {tab === "similar" && (
            <RecommendationsRow
              media={media}
              titleLanguage={titleLanguage}
              onOpen={(rid) => navigate(`/anime/${rid}`, { replace: true })}
            />
          )}
          </div>
        </div>
      </div>

      <StatusSheet
        open={statusOpen}
        onClose={() => setStatusOpen(false)}
        title={inList ? "Change status" : `Add "${title}"`}
        current={entry?.status}
        onPick={onPickStatus}
        onRemove={inList ? () => remove(animeId!) : undefined}
        disabledStatuses={getDisabledStatuses(
          entry?.airing_status ?? media.status ?? null,
        )}
      />
      {inList && animeId != null && (
        <QuickMenu
          open={editOpen}
          onClose={() => setEditOpen(false)}
          anilistId={animeId}
        />
      )}
    </div>
  );
}

/** The user's own standing on a franchise row: watched, progress, planned. */
function SeasonRowStatus({ entry }: { entry: AnimeListEntry }) {
  const meta = statusMeta(entry.status);
  const label =
    entry.status === "completed"
      ? "Watched"
      : entry.status === "plan_to_watch"
        ? "Planned"
        : entry.status === "not_interested"
          ? "Not interested"
          : `${entry.episodes_watched} / ${entry.total_episodes ?? "?"}`;
  return (
    <span className="k-seasonrow__mystatus" style={{ color: meta.color }}>
      <Icon icon={meta.icon} size={11} weight="fill" />
      {label}
    </span>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="k-detail__section">
      <Text as="h2" size="lg" weight={600} className="k-detail__sectiontitle">
        {title}
      </Text>
      {children}
    </section>
  );
}

function StaffRow({ media }: { media: AnimeMedia }) {
  const staff = media.staff ?? [];
  if (staff.length === 0) return null;
  return (
    <Section title="Staff">
      <div className="k-hscroll">
        {staff.map((s, i) => (
          <div key={i} className="k-charcard">
            <div className="k-charcard__img">
              <AnimeCover src={s.image ?? undefined} alt={s.name} decorative radius="var(--radius-full)" />
            </div>
            <Text size="xs" weight={500} clamp={2}>
              {s.name}
            </Text>
            <Text size="2xs" color="tertiary" clamp={1}>
              {s.role}
            </Text>
          </div>
        ))}
      </div>
    </Section>
  );
}

function CharactersRow({ media }: { media: AnimeMedia }) {
  const chars = media.characters ?? [];
  if (chars.length === 0) return null;
  const anyDub = chars.some((c) => c.dubActor);
  return (
    <Section title="Characters">
      <div className="k-hscroll">
        {chars.slice(0, 6).map((c, i) => (
          <div key={i} className="k-charcard">
            <div className="k-charcard__img">
              <AnimeCover src={c.image} alt={c.name} decorative radius="var(--radius-full)" />
            </div>
            <Text size="xs" weight={500} clamp={2}>
              {c.name}
            </Text>
            {/* Both casts, each tagged. The language tag only appears when the
                title actually has a dub anywhere — an all-sub show doesn't
                need every card saying "JP". */}
            {c.voiceActor && (
              <span className="k-charcard__va" title={c.voiceActor}>
                {anyDub && <span className="k-charcard__lang">JP</span>}
                <span className="k-charcard__vaname">{c.voiceActor}</span>
              </span>
            )}
            {c.dubActor && (
              <span className="k-charcard__va" title={c.dubActor}>
                <span className="k-charcard__lang">EN</span>
                <span className="k-charcard__vaname">{c.dubActor}</span>
              </span>
            )}
          </div>
        ))}
      </div>
    </Section>
  );
}

function RecommendationsRow({
  media,
  titleLanguage,
  onOpen,
}: {
  media: AnimeMedia;
  titleLanguage: TitleLanguage;
  onOpen: (id: number) => void;
}) {
  const recs = media.recommendations ?? [];
  if (recs.length === 0) return null;
  return (
    <Section title="Recommendations">
      <div className="k-hscroll">
        {recs.map((r) => (
          <button key={r.id} className="k-relcard" onClick={() => onOpen(r.id)}>
            <AnimeCover
              src={getCoverUrl(r.coverImage)}
              alt={preferredTitle(r.title, titleLanguage)}
            />
            <Text size="xs" weight={500} clamp={2}>
              {preferredTitle(r.title, titleLanguage)}
            </Text>
          </button>
        ))}
      </div>
    </Section>
  );
}

function DetailTopBar({
  solid,
  title,
  onBack,
  onShare,
}: {
  solid: boolean;
  title?: string;
  onBack: () => void;
  onShare?: () => void;
}) {
  return (
    <header className={`k-detail__topbar${solid ? " k-detail__topbar--solid" : ""}`}>
      <button type="button" className="k-icon-btn k-detail__topbtn" onClick={onBack} aria-label="Back">
        <Icon icon={ChevronLeft} size={20} />
      </button>
      {title && (
        <Text size="lg" weight={600} clamp={1} className="k-detail__topbartitle">
          {title}
        </Text>
      )}
      {onShare && (
        <button type="button" className="k-icon-btn k-detail__topbtn" onClick={onShare} aria-label="Share">
          <Icon icon={Share2} size={20} />
        </button>
      )}
    </header>
  );
}

function DetailSkeleton({ onBack }: { onBack: () => void }) {
  return (
    <div className="k-page k-detail">
      <DetailTopBar solid={false} onBack={onBack} />
      {/* An explicit "we're fetching" beat over the shimmer: bare placeholder
          shadows read as a broken/empty page while a slow request is in
          flight, so say what's happening. */}
      <div className="k-detail__loading" role="status" aria-live="polite">
        <Icon icon={Loader2} size={16} className="k-detail__spinner" />
        <span>Loading details…</span>
      </div>
      <div className="k-detail__scroll konsou-scroll">
        <Skeleton height={240} radius="0" />
        <div className="k-detail__headrow">
          <Skeleton width={120} height={180} radius="var(--radius-md)" />
          <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 10 }}>
            <Skeleton height={24} width="80%" />
            <Skeleton height={14} width="50%" />
            <Skeleton height={14} width="65%" />
          </div>
        </div>
        <div className="k-detail__body">
          <Skeleton height={48} />
          <Skeleton height={14} style={{ marginTop: 16 }} />
          <Skeleton height={14} width="92%" style={{ marginTop: 8 }} />
          <Skeleton height={14} width="85%" style={{ marginTop: 8 }} />
        </div>
      </div>
    </div>
  );
}
