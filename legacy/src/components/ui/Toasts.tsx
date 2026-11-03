import { createPortal } from "react-dom";
import { useToastStore } from "@/lib/store/toastStore";

/** Snackbar/toast renderer. Mounted once at the app root. */
export function Toasts() {
  const toasts = useToastStore((s) => s.toasts);
  const dismiss = useToastStore((s) => s.dismiss);

  if (toasts.length === 0) return null;

  return createPortal(
    <div className="k-toasts" role="status" aria-live="polite">
      {toasts.map((t) => (
        <div key={t.id} className={`k-toast k-toast--${t.tone ?? "default"}`}>
          <span className="k-toast__msg">{t.message}</span>
          {t.actionLabel && (
            <button
              type="button"
              className="k-toast__action"
              onClick={() => {
                t.onAction?.();
                dismiss(t.id);
              }}
            >
              {t.actionLabel}
            </button>
          )}
        </div>
      ))}
    </div>,
    document.body,
  );
}
