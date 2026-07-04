import { useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { pressTab } from "@/lib/navStacks";

/**
 * Shared tab-press handler for the bottom nav, sidebar and 1-5 shortcuts.
 * Navigation always replaces: browser history stays a single entry and the
 * per-tab stacks in lib/navStacks are the only back history.
 */
export function useTabPress() {
  const navigate = useNavigate();
  return useCallback(
    (to: string) => {
      const result = pressTab(to);
      if ("to" in result) navigate(result.to, { replace: true });
      else window.dispatchEvent(new CustomEvent("konsou:scrolltop"));
    },
    [navigate],
  );
}
