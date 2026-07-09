import { useEffect, useMemo, useState } from "react";
import { Download, Sparkles } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Chip } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { computeWrapped, wrappedYears } from "@/lib/wrapped";
import { preferredTitle } from "@/lib/format";
import { toast } from "@/lib/store/toastStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { WrappedStats } from "@/lib/wrapped";
import type { AnimeListEntry, TitleLanguage } from "@/types/list";

interface WrappedSheetProps {
  open: boolean;
  onClose: () => void;
  entries: AnimeListEntry[];
}

function entryTitle(e: AnimeListEntry, pref: TitleLanguage): string {
  return preferredTitle(
    { romaji: e.title_romaji, english: e.title_english, native: e.title_native },
    pref,
  );
}

/** Read a theme token off :root, with a fallback for safety. */
function cssVar(name: string, fallback: string): string {
  const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  return v || fallback;
}

/**
 * Draw the shareable card. Pure canvas, no external images, so it can never
 * taint and works fully offline. 1080x1350 (4:5) suits every feed.
 */
function renderShareCard(
  w: WrappedStats,
  pref: TitleLanguage,
): Promise<Blob> {
  const W = 1080;
  const H = 1350;
  const canvas = document.createElement("canvas");
  canvas.width = W;
  canvas.height = H;
  const ctx = canvas.getContext("2d");
  if (!ctx) return Promise.reject(new Error("canvas unavailable"));

  const accent = cssVar("--color-accent", "#ff7847");
  const glow = cssVar("--color-accent-glow", "#ffa47d");
  const ink = cssVar("--color-text-primary", "#f5ede6");
  const dim = cssVar("--color-text-secondary", "#b3a89f");
  const font = (weight: number, px: number) =>
    `${weight} ${px}px "Plus Jakarta Sans", sans-serif`;

  // Warm near-black wash with an ember bloom up top: the app's own scene.
  const bg = ctx.createLinearGradient(0, 0, 0, H);
  bg.addColorStop(0, "#1b0f08");
  bg.addColorStop(1, "#0d0705");
  ctx.fillStyle = bg;
  ctx.fillRect(0, 0, W, H);
  const bloom = ctx.createRadialGradient(W / 2, -80, 60, W / 2, -80, 700);
  bloom.addColorStop(0, accent);
  bloom.addColorStop(1, "transparent");
  ctx.globalAlpha = 0.4;
  ctx.fillStyle = bloom;
  ctx.fillRect(0, 0, W, 700);
  ctx.globalAlpha = 1;

  const cx = W / 2;
  ctx.textAlign = "center";

  ctx.fillStyle = dim;
  ctx.font = font(700, 30);
  ctx.fillText("K O N S O U   W R A P P E D", cx, 120);

  ctx.fillStyle = ink;
  ctx.font = font(800, 150);
  ctx.fillText(String(w.year), cx, 270);

  ctx.fillStyle = glow;
  ctx.font = font(800, 210);
  ctx.fillText(w.hours.toLocaleString(), cx, 540);
  ctx.fillStyle = dim;
  ctx.font = font(600, 40);
  ctx.fillText("hours of anime finished", cx, 605);

  ctx.fillStyle = ink;
  ctx.font = font(600, 44);
  ctx.fillText(
    `${w.finishedCount} shows · ${w.episodes.toLocaleString()} episodes`,
    cx,
    710,
  );
  let y = 780;
  if (w.busiestMonth) {
    ctx.fillStyle = dim;
    ctx.font = font(500, 36);
    ctx.fillText(
      `${w.busiestMonth.name} went hardest: ${w.busiestMonth.count} finishes`,
      cx,
      y,
    );
    y += 60;
  }
  if (w.meanScore != null) {
    ctx.fillStyle = dim;
    ctx.font = font(500, 36);
    ctx.fillText(`mean score ${w.meanScore.toFixed(1)}`, cx, y);
    y += 60;
  }

  if (w.topRated.length > 0) {
    y = Math.max(y + 40, 940);
    ctx.fillStyle = dim;
    ctx.font = font(700, 28);
    ctx.fillText("T O P   O F   T H E   Y E A R", cx, y);
    y += 62;
    for (const e of w.topRated) {
      ctx.fillStyle = ink;
      ctx.font = font(600, 40);
      let t = entryTitle(e, pref);
      if (t.length > 38) t = `${t.slice(0, 37)}…`;
      ctx.fillText(`${t}  ·  ${e.score}`, cx, y);
      y += 58;
    }
  }

  ctx.fillStyle = accent;
  ctx.font = font(800, 34);
  ctx.fillText("konsou", cx, H - 70);

  return new Promise((resolve, reject) =>
    canvas.toBlob(
      (b) => (b ? resolve(b) : reject(new Error("toBlob failed"))),
      "image/png",
    ),
  );
}

async function shareCard(w: WrappedStats, pref: TitleLanguage): Promise<void> {
  const blob = await renderShareCard(w, pref);
  // Clipboard first (works in the Tauri webview); file download as fallback.
  try {
    await navigator.clipboard.write([
      new ClipboardItem({ "image/png": blob }),
    ]);
    toast.success("Wrapped card copied as an image");
    return;
  } catch {
    /* clipboard unavailable: fall through to download */
  }
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `konsou-wrapped-${w.year}.png`;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 5000);
  toast.success("Wrapped card saved");
}

/** The year in review: a sheet with the story, and a card built for sharing. */
export function WrappedSheet({ open, onClose, entries }: WrappedSheetProps) {
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const years = useMemo(() => wrappedYears(entries), [entries]);
  const [year, setYear] = useState(() => years[0] ?? new Date().getFullYear());
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (open && years.length > 0) setYear(years[0]);
  }, [open, years]);

  const w = useMemo(() => computeWrapped(entries, year), [entries, year]);

  const onShare = async () => {
    setBusy(true);
    try {
      await shareCard(w, titleLanguage);
    } catch {
      toast.error("Couldn't create the image");
    } finally {
      setBusy(false);
    }
  };

  return (
    <BottomSheet open={open} onClose={onClose} title={`Your ${year}, wrapped`}>
      {years.length > 1 && (
        <div className="k-wrapped__years">
          {years.map((y) => (
            <Chip key={y} active={y === year} onClick={() => setYear(y)}>
              {y}
            </Chip>
          ))}
        </div>
      )}

      <div className="k-wrapped">
        <div className="k-wrapped__hero">
          <span className="k-wrapped__hours">{w.hours.toLocaleString()}</span>
          <span className="k-wrapped__hourslabel">
            hours of anime finished in {w.year}
          </span>
        </div>

        <p className="k-wrapped__line">
          {w.finishedCount} {w.finishedCount === 1 ? "show" : "shows"} finished
          · {w.episodes.toLocaleString()} episodes
          {w.addedCount > 0 ? ` · ${w.addedCount} added to the list` : ""}
        </p>
        {w.busiestMonth && (
          <p className="k-wrapped__line">
            {w.busiestMonth.name} went hardest with {w.busiestMonth.count}{" "}
            {w.busiestMonth.count === 1 ? "finish" : "finishes"}
            {w.meanScore != null
              ? `, and the year averaged ${w.meanScore.toFixed(1)}`
              : ""}
            .
          </p>
        )}
        {w.franchise && (
          <p className="k-wrapped__line">
            Franchise of the year:{" "}
            <strong>{entryTitle(w.franchise.display, titleLanguage)}</strong>{" "}
            with {w.franchise.count} entries closed out.
          </p>
        )}

        {w.topRated.length > 0 && (
          <>
            <p className="k-wrapped__heading">Top of the year</p>
            <ol className="k-wrapped__top">
              {w.topRated.map((e) => (
                <li key={e.anilist_id} className="k-wrapped__toprow">
                  <span className="k-wrapped__topcover">
                    <AnimeCover
                      src={e.cover_url ?? undefined}
                      alt=""
                      decorative
                      radius="var(--radius-sm)"
                    />
                  </span>
                  <Text size="sm" weight={600} clamp={1}>
                    {entryTitle(e, titleLanguage)}
                  </Text>
                  <span className="k-wrapped__topscore">★ {e.score}</span>
                </li>
              ))}
            </ol>
          </>
        )}

        {w.firstFinish && w.lastFinish && w.finishedCount > 1 && (
          <p className="k-wrapped__line k-wrapped__line--dim">
            Opened with {entryTitle(w.firstFinish, titleLanguage)}, closed with{" "}
            {entryTitle(w.lastFinish, titleLanguage)}.
          </p>
        )}

        <button
          type="button"
          className="k-btn k-btn--md k-btn--primary k-btn--block k-wrapped__share"
          onClick={() => void onShare()}
          disabled={busy || w.finishedCount === 0}
        >
          <Icon icon={busy ? Sparkles : Download} size={16} />
          {busy ? "Rendering…" : "Save as image"}
        </button>
      </div>
    </BottomSheet>
  );
}
