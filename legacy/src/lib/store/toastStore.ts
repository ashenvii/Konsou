import { create } from "zustand";

export interface Toast {
  id: number;
  message: string;
  /** Optional action button (e.g. "Undo"). */
  actionLabel?: string;
  onAction?: () => void;
  tone?: "default" | "success" | "error";
  duration: number;
}

interface ToastState {
  toasts: Toast[];
  show: (t: Omit<Toast, "id" | "duration"> & { duration?: number }) => number;
  /** Rewrite a live toast in place and restart its dismiss timer. Returns false
   *  when the toast has already gone, so the caller can open a fresh one. This
   *  is what lets a run of episode logs share ONE snackbar instead of stacking
   *  a new toast (and a new fading Undo) per tap. */
  update: (id: number, patch: Partial<Omit<Toast, "id">>) => boolean;
  dismiss: (id: number) => void;
}

let nextId = 1;
// Dismiss timers are tracked so an in-place update can restart the countdown
// rather than letting the original deadline expire mid-run.
const timers = new Map<number, ReturnType<typeof setTimeout>>();

function clearTimer(id: number): void {
  const t = timers.get(id);
  if (t) {
    clearTimeout(t);
    timers.delete(id);
  }
}

export const useToastStore = create<ToastState>((set, get) => ({
  toasts: [],
  show: (t) => {
    const id = nextId++;
    const duration = t.duration ?? 3000;
    set((s) => ({ toasts: [...s.toasts, { ...t, id, duration }] }));
    if (duration > 0) {
      timers.set(id, setTimeout(() => get().dismiss(id), duration));
    }
    return id;
  },
  update: (id, patch) => {
    const existing = get().toasts.find((t) => t.id === id);
    if (!existing) return false;
    const duration = patch.duration ?? existing.duration;
    set((s) => ({
      toasts: s.toasts.map((t) => (t.id === id ? { ...t, ...patch, id, duration } : t)),
    }));
    clearTimer(id);
    if (duration > 0) {
      timers.set(id, setTimeout(() => get().dismiss(id), duration));
    }
    return true;
  },
  dismiss: (id) => {
    clearTimer(id);
    set((s) => ({ toasts: s.toasts.filter((x) => x.id !== id) }));
  },
}));

/** Convenience helpers usable outside React. */
export const toast = {
  show: (message: string, tone: Toast["tone"] = "default") =>
    useToastStore.getState().show({ message, tone }),
  error: (message: string) =>
    useToastStore.getState().show({ message, tone: "error", duration: 4000 }),
  success: (message: string) =>
    useToastStore.getState().show({ message, tone: "success" }),
  /** A toast carrying an action button (e.g. Undo / Mark complete). */
  action: (opts: Omit<Toast, "id" | "duration"> & { duration?: number }) =>
    useToastStore.getState().show(opts),
  /** Rewrite a live toast; false when it has already been dismissed. */
  update: (id: number, patch: Partial<Omit<Toast, "id">>) =>
    useToastStore.getState().update(id, patch),
};
