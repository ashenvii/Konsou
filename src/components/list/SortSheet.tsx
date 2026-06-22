import { ArrowDown, ArrowUp, Check } from "@phosphor-icons/react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Icon } from "@/components/ui/Icon";
import { SORT_LABELS } from "./ListToolbar";
import type { SortKey, SortSpec } from "@/types/list";

interface SortSheetProps {
  open: boolean;
  onClose: () => void;
  sort: SortSpec;
  onChange: (s: SortSpec) => void;
}

const KEYS: SortKey[] = ["updated", "title", "score", "episodes", "added"];

export function SortSheet({ open, onClose, sort, onChange }: SortSheetProps) {
  return (
    <BottomSheet open={open} onClose={onClose} title="Sort by">
      <div className="k-sortlist">
        {KEYS.map((key) => {
          const active = sort.key === key;
          return (
            <button
              key={key}
              type="button"
              className={`k-sortrow${active ? " k-sortrow--active" : ""}`}
              onClick={() =>
                onChange({
                  key,
                  // toggle order when re-selecting the active key
                  order: active
                    ? sort.order === "asc"
                      ? "desc"
                      : "asc"
                    : key === "title"
                      ? "asc"
                      : "desc",
                })
              }
            >
              <span>{SORT_LABELS[key]}</span>
              {active && (
                <span className="k-sortrow__dir">
                  <Icon
                    icon={sort.order === "asc" ? ArrowUp : ArrowDown}
                    size={16}
                  />
                  <Icon icon={Check} size={16} color="var(--color-accent)" />
                </span>
              )}
            </button>
          );
        })}
      </div>
    </BottomSheet>
  );
}
