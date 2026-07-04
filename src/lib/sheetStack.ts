/**
 * Registry of currently-open sheets/modals, newest last. The Android back
 * handler consults it first: back closes the top sheet instead of navigating,
 * matching how every native app treats back while a bottom sheet is up.
 */
type Closer = () => void;

const stack: Closer[] = [];

/** Register an open sheet. Returns an unregister function for cleanup. */
export function registerSheet(close: Closer): () => void {
  stack.push(close);
  return () => {
    const i = stack.indexOf(close);
    if (i !== -1) stack.splice(i, 1);
  };
}

/** Close the most recently opened sheet. True if one was open. */
export function closeTopSheet(): boolean {
  const top = stack[stack.length - 1];
  if (!top) return false;
  top();
  return true;
}
