import { useMemo, useState } from "react";
import { X } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import {
  addHashtag,
  getHashtags,
  normalizeTagInput,
  removeHashtag,
} from "@/lib/hashtags";
import type { HashtagFacet } from "@/lib/hashtags";

interface TagPickerProps {
  /** The note being edited. Tags live inside it; this is the only storage. */
  note: string;
  onChange: (note: string) => void;
  /** The vocabulary already used across the library, most-used first. */
  suggestions: HashtagFacet[];
}

const MAX_SUGGESTIONS = 8;

/**
 * Tag entry that suggests what you already use.
 *
 * Tags are stored as `#tags` inside the note itself, so there is no second
 * field to migrate, sync or export, and the filters built on note hashtags keep
 * working untouched. What this adds is assisted *input*: your existing
 * vocabulary is offered as you type, which is the only thing that prevents the
 * drift normalization cannot fix. Casing variants already merge (#Comfort and
 * #comfort are one tag); nothing can merge #comfy and #comfort after the fact,
 * so the cure has to happen at the moment of typing.
 */
export function TagPicker({ note, onChange, suggestions }: TagPickerProps) {
  const [draft, setDraft] = useState("");

  const applied = useMemo(() => getHashtags(note), [note]);
  const appliedKeys = useMemo(
    () => new Set(applied.map((t) => t.toLowerCase())),
    [applied],
  );

  const matches = useMemo(() => {
    const typed = draft.trim().replace(/^#+/, "").toLowerCase();
    return suggestions
      .filter((s) => !appliedKeys.has(s.key))
      .filter((s) => (typed ? s.key.includes(typed) : true))
      .slice(0, MAX_SUGGESTIONS);
  }, [suggestions, appliedKeys, draft]);

  const commit = (raw: string) => {
    const tag = normalizeTagInput(raw);
    if (!tag) return;
    onChange(addHashtag(note, tag));
    setDraft("");
  };

  const vocabulary = useMemo(
    () => new Set(suggestions.map((s) => s.key)),
    [suggestions],
  );

  // "Create" is only offered for genuinely new words. If the tag is already on
  // this entry, or already exists anywhere in the library, the suggestion above
  // is the way to add it: offering to create it again is how you end up with
  // two spellings of one idea, which is the whole thing this prevents.
  const typedTag = normalizeTagInput(draft);
  const typedKey = typedTag?.toLowerCase();
  const canCreate =
    typedKey != null && !appliedKeys.has(typedKey) && !vocabulary.has(typedKey);

  return (
    <div className="k-tagpick">
      {applied.length > 0 && (
        <div className="k-tagpick__applied">
          {applied.map((tag) => (
            <span key={tag.toLowerCase()} className="k-tagpick__chip">
              {tag}
              <button
                type="button"
                className="k-tagpick__remove"
                onClick={() => onChange(removeHashtag(note, tag.toLowerCase()))}
                aria-label={`Remove ${tag}`}
              >
                <Icon icon={X} size={12} />
              </button>
            </span>
          ))}
        </div>
      )}

      <input
        className="k-tagpick__input"
        value={draft}
        placeholder="Add a tag…"
        aria-label="Add a tag"
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter") {
            e.preventDefault();
            commit(draft);
          }
          // Backspace on an empty box takes back the last tag, the behaviour
          // every tag field has.
          if (e.key === "Backspace" && draft === "" && applied.length > 0) {
            const last = applied[applied.length - 1];
            onChange(removeHashtag(note, last.toLowerCase()));
          }
        }}
      />

      {(matches.length > 0 || canCreate) && (
        <div className="k-tagpick__suggest">
          {matches.map((s) => (
            <button
              key={s.key}
              type="button"
              className="k-tagpick__sugg"
              onClick={() => commit(s.label)}
            >
              {s.label}
              <span className="k-tagpick__n">{s.count}</span>
            </button>
          ))}
          {canCreate && (
            <button
              type="button"
              className="k-tagpick__sugg k-tagpick__sugg--new"
              onClick={() => commit(draft)}
            >
              Create {typedTag}
            </button>
          )}
        </div>
      )}
    </div>
  );
}
