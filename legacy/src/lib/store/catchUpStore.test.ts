import { describe, it, expect, beforeEach } from "vitest";
import { useCatchUpStore, type CatchUpRequest } from "./catchUpStore";
import type { RelationNode } from "@/types/anime";

/**
 * The catch-up prompt is raised by a background chain walk, so two quick plan
 * adds can resolve close together. The store is a queue precisely so the second
 * one can't overwrite a prompt the user never saw — that's what these guard.
 */

const node = (id: number, relationType: RelationNode["relationType"] = "PREQUEL"): RelationNode => ({
  id,
  relationType,
  title: { romaji: `Node ${id}`, english: null, native: null },
});

const req = (rootId: number, ids: number[]): CatchUpRequest => ({
  rootId,
  primaryTitle: `Root ${rootId}`,
  candidates: ids.map((id) => node(id)),
});

describe("catchUpStore", () => {
  beforeEach(() => useCatchUpStore.setState({ queue: [] }));

  it("lines prompts up oldest-first instead of overwriting", () => {
    const { enqueue } = useCatchUpStore.getState();
    enqueue(req(1, [10]));
    enqueue(req(2, [20]));

    const { queue } = useCatchUpStore.getState();
    expect(queue.map((r) => r.rootId)).toEqual([1, 2]);
  });

  it("close advances to the next queued prompt, then empties", () => {
    const { enqueue, close } = useCatchUpStore.getState();
    enqueue(req(1, [10]));
    enqueue(req(2, [20]));

    close();
    expect(useCatchUpStore.getState().queue.map((r) => r.rootId)).toEqual([2]);
    close();
    expect(useCatchUpStore.getState().queue).toEqual([]);
  });

  it("folds a repeat of the same franchise into its waiting prompt", () => {
    const { enqueue } = useCatchUpStore.getState();
    enqueue(req(1, [10, 11]));
    enqueue(req(1, [11, 12])); // 11 already queued, 12 is new

    const { queue } = useCatchUpStore.getState();
    expect(queue).toHaveLength(1);
    expect(queue[0].candidates.map((c) => c.id)).toEqual([10, 11, 12]);
  });
});
