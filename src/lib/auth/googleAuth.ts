/**
 * Google OAuth 2.0 + PKCE.
 *
 * Both desktop and Android use the same loopback flow: the Rust `oauth_listen`
 * command binds a random 127.0.0.1 port, the system browser opens Google's
 * consent page, the redirect lands on that port, and Rust emits an
 * `oauth-callback` event with the raw callback path.
 *
 * Android originally tried a custom-URI-scheme redirect. It did reach the app,
 * but Tauri's deep-link plugin never surfaced the URL (it only tracks schemes
 * from its own config, which rejects custom schemes), so Android routes through
 * the loopback listener too. It reuses the desktop client and secret, which is
 * fine for an installed app.
 */
import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { isTauri } from "@/lib/platform";
import { openExternal } from "@/lib/openExternal";
import { generateVerifier, generateChallenge, generateState } from "./pkce";
import {
  saveTokens,
  clearTokens,
  loadTokens,
  saveAccount,
  loadAccount,
  type StoredAccount,
} from "./tokenStore";

export type GoogleAccount = StoredAccount;

// Both platforms use this client (has a secret, loopback redirect).
const DESKTOP_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID as string;
const DESKTOP_CLIENT_SECRET = import.meta.env.VITE_GOOGLE_CLIENT_SECRET as string;

const SCOPES = [
  "openid",
  "email",
  "profile",
  "https://www.googleapis.com/auth/drive.appdata",
].join(" ");

// ---------------------------------------------------------------------------
// Shared: build the Google auth URL
// ---------------------------------------------------------------------------

function buildAuthUrl(
  clientId: string,
  redirectUri: string,
  challenge: string,
  state: string,
): URL {
  const url = new URL("https://accounts.google.com/o/oauth2/v2/auth");
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("redirect_uri", redirectUri);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", SCOPES);
  url.searchParams.set("code_challenge", challenge);
  url.searchParams.set("code_challenge_method", "S256");
  url.searchParams.set("state", state);
  url.searchParams.set("access_type", "offline");
  // Required to receive a refresh_token on every sign-in.
  url.searchParams.set("prompt", "consent");
  return url;
}

// ---------------------------------------------------------------------------
// Shared: exchange code for tokens
// ---------------------------------------------------------------------------

async function exchangeCode(opts: {
  code: string;
  verifier: string;
  clientId: string;
  clientSecret: string | null;
  redirectUri: string;
}): Promise<void> {
  const body = new URLSearchParams({
    code: opts.code,
    client_id: opts.clientId,
    redirect_uri: opts.redirectUri,
    grant_type: "authorization_code",
    code_verifier: opts.verifier,
  });
  // Android client has no secret.
  if (opts.clientSecret) body.set("client_secret", opts.clientSecret);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Token exchange failed: ${err}`);
  }

  const data = await res.json() as Record<string, unknown>;

  if (!data.refresh_token) {
    throw new Error(
      "Google did not return a refresh token. " +
        "Revoke Konsou access at myaccount.google.com/permissions and try again.",
    );
  }

  saveTokens({
    access_token: data.access_token as string,
    refresh_token: data.refresh_token as string,
    expires_at: Date.now() + (data.expires_in as number) * 1000,
    scope: data.scope as string,
  });
}

async function fetchUserInfo(accessToken: string): Promise<GoogleAccount> {
  const res = await fetch("https://www.googleapis.com/oauth2/v2/userinfo", {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) throw new Error("Failed to fetch Google user info");
  const d = await res.json() as Record<string, unknown>;
  return {
    name: d.name as string,
    email: d.email as string,
    avatarUrl: (d.picture as string | undefined) ?? null,
  };
}

// ---------------------------------------------------------------------------
// Loopback flow (desktop + Android): localhost TCP server via Rust command
// ---------------------------------------------------------------------------

async function desktopOAuth(verifier: string, challenge: string, state: string): Promise<GoogleAccount> {
  if (!DESKTOP_CLIENT_ID) {
    throw new Error("VITE_GOOGLE_CLIENT_ID is not set. Add it to your .env file.");
  }

  const port = await invoke<number>("oauth_listen");
  // 127.0.0.1 rather than localhost: on Android the browser may resolve
  // localhost to ::1 (IPv6), which would miss the IPv4-bound listener.
  const redirectUri = `http://127.0.0.1:${port}/callback`;

  await openExternal(buildAuthUrl(DESKTOP_CLIENT_ID, redirectUri, challenge, state).toString());

  const callbackPath = await new Promise<string>((resolve, reject) => {
    let done = false;
    const timeout = setTimeout(() => {
      done = true;
      reject(new Error("Sign-in timed out. Please try again."));
    }, 5 * 60_000);

    listen<string>("oauth-callback", (event) => {
      if (done) return;
      done = true;
      clearTimeout(timeout);
      resolve(event.payload);
    }).catch(reject);
  });

  const params = new URLSearchParams(callbackPath.split("?")[1] ?? "");
  if (params.get("error")) throw new Error("Google sign-in was cancelled or denied.");
  const code = params.get("code");
  const returnedState = params.get("state");
  if (!code) throw new Error("OAuth: no authorization code in callback");
  if (returnedState !== state) throw new Error("OAuth: state mismatch — possible CSRF");

  await exchangeCode({
    code,
    verifier,
    clientId: DESKTOP_CLIENT_ID,
    clientSecret: DESKTOP_CLIENT_SECRET,
    redirectUri,
  });

  const tokens = loadTokens()!;
  const account = await fetchUserInfo(tokens.access_token);
  saveAccount(account);
  return account;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

export async function startGoogleOAuth(): Promise<GoogleAccount> {
  if (!isTauri()) {
    throw new Error(
      "Google sign-in requires the desktop or Android app, not available in browser preview.",
    );
  }

  const verifier = generateVerifier();
  const challenge = await generateChallenge(verifier);
  const state = generateState();

  // Desktop and Android both use the loopback listener flow.
  return desktopOAuth(verifier, challenge, state);
}

/** Restore a previously signed-in account from localStorage (call on app init). */
export function restoreGoogleAccount(): GoogleAccount | null {
  if (!loadTokens()) return null;
  return loadAccount();
}

export async function signOutGoogle(): Promise<void> {
  clearTokens();
}
