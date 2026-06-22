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
  dismiss: (id: number) => void;
}

let nextId = 1;

export const useToastStore = create<ToastState>((set, get) => ({
  toasts: [],
  show: (t) => {
    const id = nextId++;
    const duration = t.duration ?? 3000;
    set((s) => ({ toasts: [...s.toasts, { ...t, id, duration }] }));
    if (duration > 0) {
      setTimeout(() => get().dismiss(id), duration);
    }
    return id;
  },
  dismiss: (id) =>
    set((s) => ({ toasts: s.toasts.filter((x) => x.id !== id) })),
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
};
