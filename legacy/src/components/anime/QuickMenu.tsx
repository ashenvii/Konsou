import { useEffect, useMemo, useState } from "react";
import { ChevronRight, Star, Trash2 } from "lucide-react";
import { EpisodeCounter } from "./EpisodeCounter";
import { QuickHead } from "./QuickHead";
import { ScorePicker } from "./ScorePicker";
import { StatusSheet } from "./StatusSheet";
import { TagPicker } from "./TagPicker";
import { nextAct } from "./nextAct";
import { statusMeta } from "./statusMeta";
import { ItemSurface } from "@/components/ui/ItemSurface";
import { Verb, VerbRule } from "@/components/ui/Verb";
import { preferredTitle } from "@/lib/format";
import { collectHashtags } from "@/lib/hashtags";
import { getDisabledStatuses } from "@/lib/statusValidation";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { ListStatus } from "@/types/list";

interface QuickMenuProps {
  open: boolean;
  onClose: () => void;
  anilistId: number;
  /** Opens the full detail page. Omitted when already there. */
  onOpenDetails?: () => void;
  /** What the popover points at on a desktop width. Null falls back to a
   *  centred panel, which is right when the opener is a whole page section. */
  anchor?: HTMLElement | null;
}

/**
 * One surface for everything you do to a tracked entry.
 *
 * Split in two, along the line DIM draws through its own item popup: the panel
 * is what you READ, the rail beside it is what you PRESS.
 *
 * What that removed. This was six stacked sections — Progress, Status, Score,
 * Tags, Notes, Remove — each announced by its own heading, all at the same
 * weight, opened by a 56px thumbnail that was the same object weight as the
 * sections under it. Five headings of chrome before a single fact, and no start
 * to the panel at all. Status was a six-button grid of icons and words; score
 * was a minus, a value, a plus and a Clear to set a number with ten possible
 * values, where reaching 9 from nothing took five taps.
 *
 * Now: a head that is the thing you opened at the size that says so, the one
 * control that is genuinely a reading AND an act (the episode counter), and the
 * one field that cannot be a mark because it holds prose. Status and score
 * became peer surfaces opened from the rail, which is what they always were —
 * pickers — rather than grids inlined into a panel that had to be scrolled past
 * to reach the notes.
 *
 * Everything still commits immediately, so there is no Save button to hunt for
 * and no draft to lose. The note is the one exception, because writing prose one
 * keystroke at a time would mean a write per character; it commits when the
 * field loses focus or the surface closes.
 */
export function QuickMenu({
  open,
  onClose,
  anilistId,
  onOpenDetails,
  anchor = null,
}: QuickMenuProps) {
  const entry = useListStore((s) => s.map[anilistId]);
  const entries = useListStore((s) => s.entries);
  const patch = useListStore((s) => s.patch);
  const updateStatus = useListStore((s) => s.updateStatus);
  const incrementEpisodes = useListStore((s) => s.incrementEpisodes);
  const remove = useListStore((s) => s.remove);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const [noteDraft, setNoteDraft] = useState("");
  const [statusOpen, setStatusOpen] = useState(false);
  const [scoreOpen, setScoreOpen] = useState(false);

  // Re-seed whenever the surface opens or the stored note changes underneath us
  // (a tag added through the picker commits and flows back through here).
  useEffect(() => {
    if (!open) return;
    setNoteDraft(entry?.notes ?? "");
  }, [open, anilistId, entry?.notes]);

  // Closing the parent has to close what it opened. These are peer overlays
  // rather than children, so nothing else takes them down with it.
  useEffect(() => {
    if (open) return;
    setStatusOpen(false);
    setScoreOpen(false);
  }, [open]);

  const tagVocabulary = useMemo(
    () => collectHashtags(entries.map((e) => e.notes)),
    [entries],
  );

  if (!entry) return null;

  const title = preferredTitle(
    {
      romaji: entry.title_romaji,
      english: entry.title_english,
      native: entry.title_native,
    },
    titleLanguage,
  );
  const meta = statusMeta(entry.status);
  const act = nextAct(entry, title);

  const commitNote = (text: string) => {
    const value = text.trim() || null;
    if ((entry.notes ?? null) !== value) void patch(anilistId, { notes: value });
  };

  const onTagsChange = (next: string) => {
    setNoteDraft(next);
    commitNote(next);
  };

  const close = () => {
    commitNote(noteDraft);
    onClose();
  };

  const onAct = () => {
    if (act.kind === "log") void incrementEpisodes(anilistId, 1);
    else if (act.status) void updateStatus(anilistId, act.status);
  };

  const onStatusPick = (status: ListStatus) => {
    void updateStatus(anilistId, status);
    setStatusOpen(false);
  };

  /* The rail. Four marks, in the order you reach for them: out of here, what
     it is, what you thought of it, and — below a rule, because a press down
     there must not feel like the same gesture as a press up top — gone. */
  const verbs = (
    <>
      {onOpenDetails && (
        <Verb
          icon={ChevronRight}
          label={`Open the full page for ${title}`}
          onClick={() => {
            commitNote(noteDraft);
            onOpenDetails();
          }}
        />
      )}
      <Verb
        icon={meta.icon}
        label={`Change status, currently ${meta.label}`}
        onClick={() => setStatusOpen(true)}
        tint={meta.color}
      />
      <Verb
        icon={Star}
        label={entry.score != null ? `Score, currently ${entry.score}` : "Set a score"}
        onClick={() => setScoreOpen(true)}
        active={entry.score != null}
        tint={entry.score != null ? "var(--color-warning)" : undefined}
      />
      <VerbRule />
      <Verb
        icon={Trash2}
        label={`Remove ${title} from your list`}
        onClick={() => {
          remove(anilistId);
          onClose();
        }}
        danger
      />
    </>
  );

  return (
    <>
      {/* Through ItemSurface, like every other quick menu: the popover-or-sheet
          call belongs in one place, and this component used to be the one
          exception that reached past it straight to a docked sheet. That is why
          the two quick menus behaved differently on the same screen width. */}
      <ItemSurface
        anchor={anchor}
        open={open}
        onClose={close}
        ariaLabel={title}
        verbs={verbs}
      >
        <div className="k-qm">
          <QuickHead
            cover={entry.cover_url}
            // The status word, not the act's own kicker: the head says what
            // this IS, the seal says what to do about it. They agree most of
            // the time and diverge exactly where it matters — a paused show
            // reads "Paused" with a resume seal.
            kicker={meta.label}
            title={title}
            state={`${entry.episodes_watched} / ${entry.total_episodes ?? "?"} episodes`}
            seal={{
              icon: act.icon,
              label: act.label,
              onAct,
              fill: act.fill,
              disabled: act.disabled,
            }}
          />

          {/* The one control in the body, because it is the one thing here that
              is a reading and an act at the same time: the seal above logs the
              next episode, this is for saying which episode you are actually
              on. */}
          <section className="k-qm__section">
            <EpisodeCounter
              anilistId={anilistId}
              watched={entry.episodes_watched}
              total={entry.total_episodes}
              airedCeiling={entry.aired_episodes}
              size="lg"
            />
          </section>

          {entry.status === "not_interested" && (
            <p className="k-status-lockhint">
              Muted, so it won't show on your list or in schedules and alerts.
              Pick a status to bring it back, or tap Not Interested again to
              un-mute.
            </p>
          )}

          {/* Tags and notes are one field, because a tag IS a hashtag in the
              note — that is how the app stores it (collectHashtags). They were
              two sections with two headings over one string. */}
          <section className="k-qm__section">
            <h3 className="k-qm__label">Notes</h3>
            <TagPicker
              note={noteDraft}
              onChange={onTagsChange}
              suggestions={tagVocabulary}
            />
            <textarea
              className="k-qm__notes"
              rows={3}
              value={noteDraft}
              placeholder="Why you stopped, who recommended it, where to pick up…"
              onChange={(e) => setNoteDraft(e.target.value)}
              onBlur={() => commitNote(noteDraft)}
              aria-label="Notes"
            />
          </section>
        </div>
      </ItemSurface>

      <StatusSheet
        open={statusOpen}
        onClose={() => setStatusOpen(false)}
        title={title}
        current={entry.status}
        onPick={onStatusPick}
        disabledStatuses={getDisabledStatuses(entry.airing_status)}
      />
      <ScorePicker
        open={scoreOpen}
        onClose={() => setScoreOpen(false)}
        anilistId={anilistId}
        title={title}
      />
    </>
  );
}
