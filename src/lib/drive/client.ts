/**
 * Google Drive appdata REST client. All list data lives in the hidden appDataFolder
 * scope — invisible to the user in their Drive UI. Handles token refresh transparently.
 *
 * Files stored: list.json, meta.json
 */
import {
  loadTokens,
  saveTokens,
  clearTokens,
  isExpired,
  type GoogleTokens,
} from "@/lib/auth/tokenStore";
import type { DriveMeta } from "@/types/sync";
import type { AnimeListEntry } from "@/types/list";

const DRIVE_FILES = "https://www.googleapis.com/drive/v3/files";
const UPLOAD_URL = "https://www.googleapis.com/upload/drive/v3/files";
const TOKEN_URL = "https://oauth2.googleapis.com/token";

const CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID as string;
const CLIENT_SECRET = import.meta.env.VITE_GOOGLE_CLIENT_SECRET as string;

/** Thrown when tokens have expired and refresh fails — user must re-authenticate. */
export class DriveAuthError extends Error {
  override name = "DriveAuthError";
}

export interface DriveListFile {
  version: 1;
  entries: AnimeListEntry[];
  exported_at: number;
}

// ---------------------------------------------------------------------------
// Internal token management
// ---------------------------------------------------------------------------

async function refreshTokens(tokens: GoogleTokens): Promise<GoogleTokens> {
  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: tokens.refresh_token,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
    }),
  });

  if (!res.ok) {
    clearTokens();
    throw new DriveAuthError("Session expired — please sign in again");
  }

  const data = await res.json() as Record<string, unknown>;
  const refreshed: GoogleTokens = {
    ...tokens,
    access_token: data.access_token as string,
    expires_at: Date.now() + (data.expires_in as number) * 1000,
  };
  saveTokens(refreshed);
  return refreshed;
}

async function getAccessToken(): Promise<string> {
  let tokens = loadTokens();
  if (!tokens) throw new DriveAuthError("Not signed in");
  if (isExpired(tokens)) tokens = await refreshTokens(tokens);
  return tokens.access_token;
}

// ---------------------------------------------------------------------------
// File ID cache — avoids redundant list calls per session
// ---------------------------------------------------------------------------

const idCache = new Map<string, string>();

async function findFileId(name: string, token: string): Promise<string | null> {
  if (idCache.has(name)) return idCache.get(name)!;

  const url = new URL(DRIVE_FILES);
  url.searchParams.set("spaces", "appDataFolder");
  url.searchParams.set("q", `name = '${name}'`);
  url.searchParams.set("fields", "files(id)");

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) return null;

  const data = await res.json() as { files?: { id: string }[] };
  const id = data.files?.[0]?.id ?? null;
  if (id) idCache.set(name, id);
  return id;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

export async function driveRead<T>(name: string): Promise<T | null> {
  const token = await getAccessToken();
  const id = await findFileId(name, token);
  if (!id) return null;

  const res = await fetch(`${DRIVE_FILES}/${id}?alt=media`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) return null;
  return res.json() as Promise<T>;
}

export async function driveWrite(name: string, data: unknown): Promise<void> {
  const token = await getAccessToken();
  const body = JSON.stringify(data);
  const existingId = await findFileId(name, token);

  if (existingId) {
    const res = await fetch(
      `${UPLOAD_URL}/${existingId}?uploadType=media`,
      {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body,
      },
    );
    if (!res.ok) throw new Error(`Drive write failed: ${res.status}`);
  } else {
    // Multipart create so we can set the name and parent in one request.
    const boundary = "konsou-mp-boundary";
    const meta = JSON.stringify({ name, parents: ["appDataFolder"] });
    const multipart =
      `--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${meta}\r\n` +
      `--${boundary}\r\nContent-Type: application/json\r\n\r\n${body}\r\n` +
      `--${boundary}--`;

    const res = await fetch(
      `${UPLOAD_URL}?uploadType=multipart`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": `multipart/related; boundary=${boundary}`,
        },
        body: multipart,
      },
    );
    if (!res.ok) throw new Error(`Drive create failed: ${res.status}`);
    const created = await res.json() as { id: string };
    idCache.set(name, created.id);
  }
}

export async function driveReadMeta(): Promise<DriveMeta | null> {
  return driveRead<DriveMeta>("meta.json");
}
