import { BottomSheet } from "./BottomSheet";
import { Button } from "./Button";
import { Icon } from "./Icon";
import { Text } from "./Text";
import type { IconComponent } from "./Icon";

interface ConfirmSheetProps {
  open: boolean;
  onClose: () => void;
  title: string;
  message: string;
  confirmLabel: string;
  onConfirm: () => void;
  /** Renders the confirm button in the destructive style. */
  danger?: boolean;
  icon?: IconComponent;
}

/** A small, reusable confirmation prompt for irreversible actions like
 *  clearing the list. Same sheet vocabulary as everything else in the app. */
export function ConfirmSheet({
  open,
  onClose,
  title,
  message,
  confirmLabel,
  onConfirm,
  danger = false,
  icon,
}: ConfirmSheetProps) {
  return (
    <BottomSheet open={open} onClose={onClose} title={title}>
      <div className="k-confirm">
        {icon && (
          <span className={`k-confirm__icon${danger ? " k-confirm__icon--danger" : ""}`}>
            <Icon icon={icon} size={24} />
          </span>
        )}
        <Text size="base" color="secondary" className="k-confirm__msg">
          {message}
        </Text>
        <div className="k-confirm__actions">
          <Button variant="secondary" block onClick={onClose}>
            Cancel
          </Button>
          <Button
            variant={danger ? "danger" : "primary"}
            block
            onClick={() => {
              onConfirm();
              onClose();
            }}
          >
            {confirmLabel}
          </Button>
        </div>
      </div>
    </BottomSheet>
  );
}
