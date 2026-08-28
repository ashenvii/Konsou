// Stage 2 entry: run the app's own resolveFranchiseChain over every pooled id
// so franchise_root_id in the generated list matches what Konsou itself would
// compute. Resumable via roots.json; relation fetches cached on disk.
import fs from "node:fs";
import { resolveFranchiseChain } from "@/lib/franchise/cascade";
// esbuild aliases this to devdata/rootres/client-stub.mjs.
import { getRequestCount } from "@/lib/api/anilist/client";

const dir = new URL("./", import.meta.url);
const pool: any[] = JSON.parse(
  fs.readFileSync(new URL("media-pool-real.json", dir), "utf8"),
);
const rootsPath = new URL("roots.json", dir);
const roots: Record<number, number> = fs.existsSync(rootsPath)
  ? JSON.parse(fs.readFileSync(rootsPath, "utf8"))
  : {};

const inList = new Set<number>(pool.map((m) => m.id));
let processed = 0;
let sinceSave = 0;

for (const media of pool) {
  processed++;
  if (roots[media.id] != null) continue;
  try {
    const { rootId, toUpdate } = await resolveFranchiseChain(
      media.id,
      inList,
      "low",
      media.title,
    );
    roots[media.id] = rootId;
    for (const id of toUpdate) {
      if (roots[id] == null) roots[id] = rootId;
    }
  } catch (e) {
    console.warn(`walk failed for ${media.id} (${media.title?.romaji}): ${e}`);
    // Leave unresolved; a rerun retries it. Do not stamp a guess.
  }
  if (++sinceSave >= 25) {
    fs.writeFileSync(rootsPath, JSON.stringify(roots));
    sinceSave = 0;
    console.log(
      `progress ${processed}/${pool.length} pooled, ${Object.keys(roots).length} rooted, ${getRequestCount()} api requests`,
    );
  }
}

fs.writeFileSync(rootsPath, JSON.stringify(roots));

const groups = new Map<number, number>();
for (const id of inList) {
  const r = roots[id] ?? id;
  groups.set(r, (groups.get(r) ?? 0) + 1);
}
const multi = [...groups.values()].filter((n) => n > 1);
console.log(
  `DONE roots: ${Object.keys(roots).length}/${pool.length} resolved, ` +
    `${multi.length} multi-member franchises covering ${multi.reduce((a, b) => a + b, 0)} entries, ` +
    `${getRequestCount()} api requests this run`,
);
