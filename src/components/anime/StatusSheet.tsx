import { Trash } from "@phosphor-icons/react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Icon } from "@/components/ui/Icon";
import { LIST_STATUSES } from "@/types/list";
import type { ListStatus } from "@/types/list";
import { statusMeta } from "./statusMeta";

interface StatusSheetProps {
  open: boolean;
  onClose: () => void;
  title: string;
  current?: ListStatus;
  onPick: (status: ListStatus) => void;
  onRemove?: () => void;
}

/** The 2×3 status picker used for quick-add and status changes. */
export function StatusSheet({
  open,
  onClose,
  title,
  current,
  onPick,
  onRemove,
}: StatusSheetProps) {
  return (
    <BottomSheet open={open} onClose={onClose} title={title}>
      <div className="k-status-grid">
        {LIST_STATUSES.map((s) => {
          const meta = statusMeta(s);
          const active = s === current;
          return (
            <button
              key={s}
              type="button"
              className={`k-status-option${active ? " k-status-option--active" : ""}`}
              style={active ? { borderColor: meta.color } : undefined}
              onClick={() => {
                onPick(s);
                onClose();
              }}
            >
              <Icon
                icon={meta.icon}
                size={24}
                weight={active ? "fill" : "regular"}
                color={meta.color}
              />
              <span>{meta.label}</span>
            </button>
          );
        })}
      </div>
      {onRemove && (
        <button
          type="button"
          className="k-status-remove"
          onClick={() => {
            onRemove();
            onClose();
          }}
        >
          <Icon icon={Trash} size={18} color="var(--color-error)" />
          Remove from list
        </button>
      )}
    </BottomSheet>
  );
}
