import { useState } from "react";
import { useStorageStore } from "@/lib/store/storageStore";
import { toast } from "@/lib/store/toastStore";

/**
 * Fatal, non-dismissable banner shown when the local database fails to open.
 * Everything DB-backed (list, alerts, adding) is dead in that state, so this
 * says so plainly and hands over the exact error to copy into a bug report,
 * instead of the app silently degrading to a Discover-only shell.
 */
export function StorageBanner() {
  const failed = useStorageStore((s) => s.failed);
  const error = useStorageStore((s) => s.error);
  const [copied, setCopied] = useState(false);

  if (!failed) return null;

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(error ?? "unknown storage error");
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      toast.show("Could not copy", "default");
    }
  };

  return (
    <div className="k-storage-banner" role="alert">
      <div className="k-storage-banner__body">
        <p className="k-storage-banner__title">Local storage did not start</p>
        <p className="k-storage-banner__detail">
          Your list, alerts, and adding are unavailable until this is fixed.
          Restart the app; if it keeps happening, send this error.
        </p>
        {error && <code className="k-storage-banner__error">{error}</code>}
      </div>
      <button type="button" className="k-storage-banner__copy" onClick={copy}>
        {copied ? "Copied" : "Copy error"}
      </button>
    </div>
  );
}
