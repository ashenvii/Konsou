import { isTauri } from "@/lib/platform";
import type { KonsouDb } from "./contract";
import { WebKonsouDb } from "./webDb";

let instance: KonsouDb | null = null;
let initPromise: Promise<KonsouDb> | null = null;

/** Lazily create + initialize the right backend exactly once. */
export async function getDb(): Promise<KonsouDb> {
  if (instance) return instance;
  if (initPromise) return initPromise;

  initPromise = (async () => {
    let db: KonsouDb;
    if (isTauri()) {
      // Dynamic import keeps the tauri-plugin-sql code out of the web bundle.
      const { TauriKonsouDb } = await import("./tauriDb");
      db = new TauriKonsouDb();
    } else {
      db = new WebKonsouDb();
    }
    await db.init();
    instance = db;
    return db;
  })();

  return initPromise;
}

export type { KonsouDb } from "./contract";
