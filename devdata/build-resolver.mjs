// Bundle rootres/entry.ts with the app's franchise code into resolve-roots.mjs.
// The "@/..." alias maps into src/, except the anilist client which is swapped
// for the throttled Node stub.
import path from "node:path";
import { fileURLToPath } from "node:url";
import fs from "node:fs";
import esbuild from "esbuild";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "..");
const stub = path.join(here, "rootres", "client-stub.mjs");

const aliasPlugin = {
  name: "konsou-alias",
  setup(build) {
    build.onResolve({ filter: /^@\// }, (args) => {
      if (args.path === "@/lib/api/anilist/client") return { path: stub };
      const base = path.join(repo, "src", args.path.slice(2));
      for (const cand of [base + ".ts", base + ".tsx", path.join(base, "index.ts")]) {
        if (fs.existsSync(cand)) return { path: cand };
      }
      return { errors: [{ text: `unresolved alias import: ${args.path}` }] };
    });
  },
};

await esbuild.build({
  entryPoints: [path.join(here, "rootres", "entry.ts")],
  bundle: true,
  platform: "node",
  format: "esm",
  target: "node20",
  outfile: path.join(here, "resolve-roots.mjs"),
  plugins: [aliasPlugin],
  logLevel: "info",
});
console.log("built devdata/resolve-roots.mjs");
