import {
  ArrowsClockwise,
  BookmarkSimple,
  CheckCircle,
  PauseCircle,
  PlayCircle,
  XCircle,
} from "@phosphor-icons/react";
import type { IconComponent } from "@/components/ui/Icon";
import { listStatusLabel } from "@/lib/format";
import type { ListStatus } from "@/types/list";

export interface StatusMeta {
  status: ListStatus;
  label: string;
  icon: IconComponent;
  color: string; // CSS var reference
}

const ICONS: Record<ListStatus, IconComponent> = {
  watching: PlayCircle,
  completed: CheckCircle,
  plan_to_watch: BookmarkSimple,
  on_hold: PauseCircle,
  dropped: XCircle,
  rewatching: ArrowsClockwise,
};

export function statusMeta(status: ListStatus): StatusMeta {
  return {
    status,
    label: listStatusLabel(status),
    icon: ICONS[status],
    color: `var(--color-status-${status})`,
  };
}
