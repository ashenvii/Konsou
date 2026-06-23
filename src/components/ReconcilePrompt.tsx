import { useState } from "react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { Text } from "@/components/ui/Text";
import { useReconcileStore } from "@/lib/store/reconcileStore";
import type { ReconcileStrategy } from "@/lib/sync/syncManager";

/**
 * Shown after sign-in when both this device and the user's Drive backup already
 * hold list data. Step 1 offers Merge / Use Drive / Use Local; the two
 * destructive choices require a second "are you sure?" confirmation before they
 * run. Mounted once, globally, in AppShell.
 */
export function ReconcilePrompt() {
  const open = useReconcileStore((s) => s.open);
  const localCount = useReconcileStore((s) => s.localCount);
  const remoteCount = useReconcileStore((s) => s.remoteCount);
  const busy = useReconcileStore((s) => s.busy);
  const resolve = useReconcileStore((s) => s.resolve);

  // Which destructive choice is awaiting confirmation (null = step 1).
  const [confirm, setConfirm] = useState<"use_drive" | "use_local" | null>(null);

  if (!open) return null;

  const run = (strategy: ReconcileStrategy) => {
    void resolve(strategy);
  };

  if (confirm) {
    const wipes = confirm === "use_drive" ? localCount : remoteCount;
    const keeps = confirm === "use_drive" ? remoteCount : localCount;
    const target = confirm === "use_drive" ? "this device's" : "your Drive backup's";
    return (
      <BottomSheet open onClose={() => {}} title="Are you sure?" dismissable={false}>
        <div className="k-reconcile">
          <Text size="base" color="secondary">
            This replaces {target} {wipes} {wipes === 1 ? "item" : "items"} with
            the other {keeps}. It can't be undone.
          </Text>
          <div className="k-reconcile__actions">
            <Button
              variant="danger"
              block
              disabled={busy}
              onClick={() => run(confirm)}
            >
              Yes, replace
            </Button>
            <Button
              variant="ghost"
              block
              disabled={busy}
              onClick={() => setConfirm(null)}
            >
              Go back
            </Button>
          </div>
        </div>
      </BottomSheet>
    );
  }

  return (
    <BottomSheet open onClose={() => {}} title="Sync your list" dismissable={false}>
      <div className="k-reconcile">
        <Text size="base" color="secondary">
          You have {localCount} {localCount === 1 ? "item" : "items"} on this
          device and {remoteCount} in your Drive backup. How should we combine
          them?
        </Text>
        <div className="k-reconcile__actions">
          <Button variant="primary" block disabled={busy} onClick={() => run("merge")}>
            Merge both (recommended)
          </Button>
          <Button
            variant="secondary"
            block
            disabled={busy}
            onClick={() => setConfirm("use_drive")}
          >
            Use Drive — replace this device
          </Button>
          <Button
            variant="secondary"
            block
            disabled={busy}
            onClick={() => setConfirm("use_local")}
          >
            Use this device — replace Drive
          </Button>
        </div>
      </div>
    </BottomSheet>
  );
}
