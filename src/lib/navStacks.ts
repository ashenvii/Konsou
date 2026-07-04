import { create } from "zustand";
import { NAV_ITEMS } from "@/components/layout/navConfig";

/**
 * App-owned navigation stacks, one per tab. Browser history is kept at a
 * single entry (every navigation replaces), so back can never unwind the
 * whole session or hop between tabs. Instead:
 *
 *  - Opening a page (detail, settings) pushes onto the CURRENT tab's stack.
 *  - Back pops the current tab's stack; at the tab root the only step left
 *    is "press back again to exit".
 *  - Switching tabs lands on that tab's stack top, so each tab continues
 *    where it left off.
 *  - Re-tapping the active tab while deep in a sequence resets it to the
 *    tab root but stashes the sequence; tapping again restores it. Any
 *    click inside the page content while a stash exists forgets it.
 */

export const TAB_ROOTS: string[] = NAV_ITEMS.map((i) => i.to);

interface NavStacksState {
  /** Tab root path → stack of paths, stack[0] === root. */
  stacks: Record<string, string[]>;
  /** Which tab owns non-tab pages (detail, settings) right now. */
  currentTab: string;
  /** Sequence stashed by a reset re-tap, restorable by the next re-tap. */
  stash: Record<string, string[] | null>;
}

const initialStacks = () =>
  Object.fromEntries(TAB_ROOTS.map((r) => [r, [r]]));

export const useNavStacks = create<NavStacksState>(() => ({
  stacks: initialStacks(),
  currentTab: TAB_ROOTS[0],
  stash: {},
}));

const top = (stack: string[]) => stack[stack.length - 1];

/** Paths that never join a tab stack (OAuth workaround route). */
const isUntracked = (path: string) => path === "/auth-redirect";

/**
 * Called on every router location change. Attributes the new path to the
 * right tab and keeps that tab's stack consistent, whether the change came
 * from our own helpers (already at stack top: no-op) or from a plain
 * navigate()/redirect.
 */
export function recordNavigation(path: string) {
  if (isUntracked(path)) return;
  const { stacks, currentTab, stash } = useNavStacks.getState();

  if (TAB_ROOTS.includes(path)) {
    // Landing on a tab root directly: that tab is now current. If the router
    // got here on its own (redirect, deep link) while the stack said we were
    // deeper, the root is the new truth.
    const stack = stacks[path];
    useNavStacks.setState({
      currentTab: path,
      stacks: top(stack) === path ? stacks : { ...stacks, [path]: [path] },
    });
    return;
  }

  const stack = stacks[currentTab];
  if (top(stack) === path) return; // our own pressTab/goBack navigation
  const next = [...stack, path];
  useNavStacks.setState({
    stacks: { ...stacks, [currentTab]: next },
    // Navigating somewhere new is activity: the stashed sequence is stale.
    stash: stash[currentTab] ? { ...stash, [currentTab]: null } : stash,
  });
}

export type TabPressResult =
  | { to: string }
  | { scrollTop: true };

/**
 * Tab press policy (bottom nav, sidebar, 1-5 shortcuts):
 *  - other tab      → continue where that tab left off
 *  - same tab, deep → reset to root, stash the sequence
 *  - same tab, root → restore the stash if one exists, else scroll to top
 */
export function pressTab(tab: string): TabPressResult {
  const { stacks, currentTab, stash } = useNavStacks.getState();

  if (currentTab !== tab) {
    useNavStacks.setState({ currentTab: tab });
    return { to: top(stacks[tab]) };
  }

  const stack = stacks[tab];
  if (stack.length > 1) {
    useNavStacks.setState({
      stacks: { ...stacks, [tab]: [tab] },
      stash: { ...stash, [tab]: stack },
    });
    return { to: tab };
  }

  const saved = stash[tab];
  if (saved && saved.length > 1) {
    useNavStacks.setState({
      stacks: { ...stacks, [tab]: saved },
      stash: { ...stash, [tab]: null },
    });
    return { to: top(saved) };
  }

  return { scrollTop: true };
}

/**
 * Pops the current tab's stack. Returns the path to navigate to (replace),
 * or null when already at the tab root (caller runs the exit policy).
 */
export function popBack(): string | null {
  const { stacks, currentTab } = useNavStacks.getState();
  const stack = stacks[currentTab];
  if (stack.length <= 1) return null;
  const next = stack.slice(0, -1);
  useNavStacks.setState({ stacks: { ...stacks, [currentTab]: next } });
  return top(next);
}

/** A click inside the page content forgets the stashed sequence. */
export function clearStash() {
  const { currentTab, stash } = useNavStacks.getState();
  if (!stash[currentTab]) return;
  useNavStacks.setState({ stash: { ...stash, [currentTab]: null } });
}
