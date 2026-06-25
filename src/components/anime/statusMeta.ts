import {
  Bookmark,
  CircleCheck,
  CirclePause,
  CirclePlay,
  CircleX,
  RotateCw,
} from "lucide-react";
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
  watching: CirclePlay,
  completed: CircleCheck,
  plan_to_watch: Bookmark,
  on_hold: CirclePause,
  dropped: CircleX,
  rewatching: RotateCw,
};

export function statusMeta(status: ListStatus): StatusMeta {
  return {
    status,
    label: listStatusLabel(status),
    icon: ICONS[status],
    color: `var(--color-status-${status})`,
  };
}
