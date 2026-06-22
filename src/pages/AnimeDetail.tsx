import { useEffect, useMemo, useRef, useState } from "react";
import type { ReactNode, UIEvent } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  CaretLeft,
  Export,
  Plus,
  Star,
  TelevisionSimple,
} from "@phosphor-icons/react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { EditSheet } from "@/components/anime/EditSheet";
import { EpisodeCounter } from "@/components/anime/EpisodeCounter";
import { StatusBadge } from "@/components/anime/StatusBadge";
import { StatusSheet } from "@/components/anime/StatusSheet";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { Skeleton } from "@/components/ui/Skeleton";
import { Text } from "@/components/ui/Text";
import { useAnimeDetail } from "@/hooks/useAniList";
import {
  airingStatusLabel,
  formatFuzzyDate,
  formatLabel,
  formatScore,
  getCoverUrl,
  preferredTitle,
  secondaryTitle,
  seasonYearLabel,
  stripHtml,
} from "@/lib/format";
import { openExternal } from "@/lib/openExternal";
import { toast } from "@/lib/store/toastStore";
import { useListStore } from "@/lib/store/listStore";
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
  RelationType,
} from "@/types/anime";
import type { ListStatus } from "@/types/list";

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
}

function fuzzyToUnixSeconds(d?: FuzzyDate | null): number | null {
  if (!d?.year) return null;
  return Math.floor(Date.UTC(d.year, (d.month ?? 1) - 1, d.day ?? 1) / 1000);
}

function relationTypeLabel(type?: RelationType | "CURRENT" | null): string {
  if (!type || type === "CURRENT") return "Current";
  return type.replace(/_/g, " ").toLowerCase();
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

function getSeasonRows(media: AnimeMedia): SeasonRow[] {
  const rows: SeasonRow[] = [
    {
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
    },
  ];

  rows.push(
    ...(media.relations ?? [])
      .filter((r) => SEASON_RELATIONS.includes(r.relationType))
      .map(
        (r): SeasonRow => ({
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
        }),
      ),
  );

  return rows.sort((a, b) => {
    const at = fuzzyToUnixSeconds(a.startDate) ?? a.seasonYear ?? 0;
    const bt = fuzzyToUnixSeconds(b.startDate) ?? b.seasonYear ?? 0;
    return at - bt;
  });
}

function seasonLabel(row: SeasonRow): string {
  const bits = [
    formatLabel(row.format),
    seasonYearLabel(row),
    airingStatusLabel(row.status),
    row.episodes ? `${row.episodes} eps` : null,
  ].filter(Boolean);
  return bits.join(" · ");
}

function releaseMeta(media: AnimeMedia): string[] {
  return [
    airingStatusLabel(media.status),
    formatFuzzyDate(media.startDate),
    media.episodes ? `${media.episodes} eps` : null,
  ].filter((v): v is string => Boolean(v));
}

export function AnimeDetail() {
  const { id } = useParams();
  const animeId = id ? Number(id) : null;
  const navigate = useNavigate();
  const { data: media, isLoading, isError } = useAnimeDetail(animeId);

  const entry = useListStore((s) => (animeId ? s.map[animeId] : undefined));
  const addFromSummary = useListStore((s) => s.addFromSummary);
  const updateStatus = useListStore((s) => s.updateStatus);
  const setDubStatus = useListStore((s) => s.setDubStatus);
  const remove = useListStore((s) => s.remove);

  const [statusOpen, setStatusOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  const [synopsisOpen, setSynopsisOpen] = useState(false);
  const [topbarSolid, setTopbarSolid] = useState(false);
  const bannerRef = useRef<HTMLDivElement>(null);

  const title = media ? preferredTitle(media.title) : "";
  const secondary = media ? secondaryTitle(media.title) : null;
  const inList = !!entry;

  const metaBits = media
    ? [
        formatLabel(media.format),
        media.episodes ? `${media.episodes} eps` : null,
        seasonYearLabel(media),
        media.studio,
      ].filter(Boolean)
    : [];

  const seasonRows = useMemo(() => (media ? getSeasonRows(media) : []), [media]);
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
  const releaseBits = media ? releaseMeta(media) : [];

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

  if (isLoading) return <DetailSkeleton onBack={() => navigate(-1)} />;
  if (isError || !media)
    return (
      <div className="k-page">
        <DetailTopBar solid onBack={() => navigate(-1)} onShare={share} />
        <EmptyState
          title="Couldn't load details"
          subtitle="Check your connection and try again."
        />
      </div>
    );

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
        onBack={() => navigate(-1)}
        onShare={share}
      />

      <div className="k-detail__scroll konsou-scroll" onScroll={onScroll}>
        <div className="k-detail__hero">
          <div className="k-detail__banner" ref={bannerRef}>
            {media.bannerImage && (
              <img src={media.bannerImage} alt="" role="presentation" />
            )}
          </div>
          <div className="k-detail__heroscrim" />
        </div>

        <div className="k-detail__headrow">
          <div className="k-detail__cover">
            <AnimeCover src={getCoverUrl(media.coverImage)} alt={title} />
          </div>
          <div className="k-detail__headinfo">
            <Text as="h1" size="2xl" weight={700} clamp={3}>
              {title}
            </Text>
            {secondary && (
              <Text size="sm" color="secondary" clamp={1}>
                {secondary}
              </Text>
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
          </div>
        </div>

        <div className="k-detail__body">
          {/* User controls */}
          {entry ? (
            <div className="k-detail__controls">
              <StatusBadge
                status={entry.status}
                onClick={() => setStatusOpen(true)}
              />
              <EpisodeCounter
                anilistId={animeId!}
                watched={entry.episodes_watched}
                total={entry.total_episodes}
                onReachedTotal={() => {
                  if (entry.status !== "completed") {
                    toast.action({
                      message: "Reached the final episode",
                      actionLabel: "Mark complete",
                      duration: 5000,
                      onAction: () => void updateStatus(animeId!, "completed"),
                    });
                  }
                }}
              />
              <button
                type="button"
                className="k-detail__score"
                onClick={() => setEditOpen(true)}
                aria-label="Edit score"
              >
                <Icon icon={Star} size={16} weight={entry.score != null ? "fill" : "regular"} color="var(--color-warning)" />
                {formatScore(entry.score)}
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

          <section className="k-detail__section">
            <Text as="h2" size="lg" weight={600} className="k-detail__sectiontitle">
              Release
            </Text>
            <div className="k-releasegrid">
              <div>
                <span>Release status</span>
                <strong>{releaseBits[0] ?? "Unknown"}</strong>
              </div>
              <div>
                <span>First aired</span>
                <strong>{releaseBits[1] ?? "Unknown"}</strong>
              </div>
              <div>
                <span>Episodes</span>
                <strong>{releaseBits[2] ?? "Unknown"}</strong>
              </div>
            </div>
          </section>

          {seasonRows.length > 1 && (
            <Section title="Related Series">
              <div className="k-seasonrows">
                {seasonRows.map((row) => (
                  <button
                    key={row.id}
                    type="button"
                    className="k-seasonrow"
                    onClick={() => navigate(`/anime/${row.id}`)}
                  >
                    <AnimeCover src={getCoverUrl(row.coverImage)} alt={preferredTitle(row.title)} />
                    <div className="k-seasonrow__body">
                      <Text size="base" weight={600} clamp={2}>
                        {preferredTitle(row.title)}
                      </Text>
                      <Text size="xs" color="secondary" clamp={2}>
                        {seasonLabel(row)}
                      </Text>
                      <span className="k-seasonrow__type">
                        {relationTypeLabel(row.relationType)}
                      </span>
                    </div>
                  </button>
                ))}
              </div>
            </Section>
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

          {/* Genres */}
          {media.genres && media.genres.length > 0 && (
            <section className="k-detail__section">
              <div className="k-chiprow k-chiprow--scroll">
                {media.genres.map((g) => (
                  <span key={g} className="k-genre">
                    {g}
                  </span>
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
                        <TelevisionSimple size={16} />
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

          <CharactersRow media={media} />
          <StaffRow media={media} />
          <RecommendationsRow media={media} onOpen={(rid) => navigate(`/anime/${rid}`)} />
        </div>
      </div>

      <StatusSheet
        open={statusOpen}
        onClose={() => setStatusOpen(false)}
        title={inList ? "Change status" : `Add "${title}"`}
        current={entry?.status}
        onPick={onPickStatus}
        onRemove={inList ? () => remove(animeId!) : undefined}
      />
      {inList && animeId != null && (
        <EditSheet open={editOpen} onClose={() => setEditOpen(false)} anilistId={animeId} />
      )}
    </div>
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
            {c.voiceActor && (
              <Text size="2xs" color="tertiary" clamp={1}>
                {c.voiceActor}
              </Text>
            )}
          </div>
        ))}
      </div>
    </Section>
  );
}

function RecommendationsRow({
  media,
  onOpen,
}: {
  media: AnimeMedia;
  onOpen: (id: number) => void;
}) {
  const recs = media.recommendations ?? [];
  if (recs.length === 0) return null;
  return (
    <Section title="Recommendations">
      <div className="k-hscroll">
        {recs.map((r) => (
          <button key={r.id} className="k-relcard" onClick={() => onOpen(r.id)}>
            <AnimeCover src={getCoverUrl(r.coverImage)} alt={preferredTitle(r.title)} />
            <Text size="xs" weight={500} clamp={2}>
              {preferredTitle(r.title)}
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
        <Icon icon={CaretLeft} size={20} />
      </button>
      {title && (
        <Text size="lg" weight={600} clamp={1} className="k-detail__topbartitle">
          {title}
        </Text>
      )}
      {onShare && (
        <button type="button" className="k-icon-btn k-detail__topbtn" onClick={onShare} aria-label="Share">
          <Icon icon={Export} size={20} />
        </button>
      )}
    </header>
  );
}

function DetailSkeleton({ onBack }: { onBack: () => void }) {
  return (
    <div className="k-page k-detail">
      <DetailTopBar solid={false} onBack={onBack} />
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
