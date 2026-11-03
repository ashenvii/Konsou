import "@testing-library/jest-dom/vitest";
import { afterEach } from "vitest";
import { cleanup } from "@testing-library/react";

// Unmount anything a component test rendered, so a leftover tree can't leak
// into the next test's queries.
afterEach(() => {
  cleanup();
});
