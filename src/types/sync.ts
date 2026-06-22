/** Google Drive sync types. Drive I/O is stubbed in v1 but the contracts are real. */

export type SyncResult = "success" | "conflict" | "error" | "idle";

export interface SyncState {
  last_sync_at: number | null;
  last_sync_result: SyncResult;
  device_id: string;
}

/** meta.json stored in Drive appdata — drives pull/push decisions. */
export interface DriveMeta {
  sync_version: number;
  last_device_id: string;
  last_sync_at: number;
  app_version: string;
}
