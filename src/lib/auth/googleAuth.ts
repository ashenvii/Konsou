/**
 * Google OAuth 2.0 + PKCE — dual-platform implementation.
 *
 * Desktop (Windows / macOS / Linux):
 *   Rust `oauth_listen` command binds a random localhost port → system browser
 *   opens Google's consent page → redirect lands on that port → Rust emits
 *   `oauth-callback` event with the raw callback path.
 *
 * Android:
 *   Tauri deep-link plugin registers the `konsou://` scheme → Chrome opens
 *   Google's consent page → redirect fires `konsou://callback?code=...` → OS
 *   hands the URL back to the app → `onOpenUrl` fires with the full URL.
 *   Android uses a separate OAuth client (no client secret — verified by
 *   package name + SHA-1 fingerprint instead).
 */
import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { open } from "@tauri-apps/plugin-shell";
import { onOpenUrl } from "@tauri-apps/plugin-deep-link";
import { isTauri, isAndroidUA } from "@/lib/platform";
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

// Desktop client — has a secret, uses localhost redirect.
const DESKTOP_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID as string;
const DESKTOP_CLIENT_SECRET = import.meta.env.VITE_GOOGLE_CLIENT_SECRET as string;

// Android client — no secret, verified by package name + SHA-1.
const ANDROID_CLIENT_ID = import.meta.env.VITE_GOOGLE_ANDROID_CLIENT_ID as string;
const ANDROID_REDIRECT_URI = "konsou://callback";

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
// Desktop flow — localhost TCP server via Rust command
// ---------------------------------------------------------------------------

async function desktopOAuth(verifier: string, challenge: string, state: string): Promise<GoogleAccount> {
  if (!DESKTOP_CLIENT_ID) {
    throw new Error("VITE_GOOGLE_CLIENT_ID is not set. Add it to your .env file.");
  }

  const port = await invoke<number>("oauth_listen");
  const redirectUri = `http://localhost:${port}/callback`;

  await open(buildAuthUrl(DESKTOP_CLIENT_ID, redirectUri, challenge, state).toString());

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
// Android flow — deep link via konsou://callback
// ---------------------------------------------------------------------------

async function androidOAuth(verifier: string, challenge: string, state: string): Promise<GoogleAccount> {
  if (!ANDROID_CLIENT_ID) {
    throw new Error("VITE_GOOGLE_ANDROID_CLIENT_ID is not set. Add it to your .env file.");
  }

  await open(
    buildAuthUrl(ANDROID_CLIENT_ID, ANDROID_REDIRECT_URI, challenge, state).toString(),
  );

  const callbackUrl = await new Promise<string>((resolve, reject) => {
    let done = false;
    const timeout = setTimeout(() => {
      done = true;
      reject(new Error("Sign-in timed out. Please try again."));
    }, 5 * 60_000);

    onOpenUrl((urls) => {
      if (done) return;
      const url = urls.find((u) => u.startsWith("konsou://callback"));
      if (!url) return;
      done = true;
      clearTimeout(timeout);
      resolve(url);
    }).catch(reject);
  });

  const url = new URL(callbackUrl);
  if (url.searchParams.get("error")) throw new Error("Google sign-in was cancelled or denied.");
  const code = url.searchParams.get("code");
  const returnedState = url.searchParams.get("state");
  if (!code) throw new Error("OAuth: no authorization code in callback");
  if (returnedState !== state) throw new Error("OAuth: state mismatch — possible CSRF");

  // Android client has no secret.
  await exchangeCode({
    code,
    verifier,
    clientId: ANDROID_CLIENT_ID,
    clientSecret: null,
    redirectUri: ANDROID_REDIRECT_URI,
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
      "Google sign-in requires the desktop or Android app — not available in browser preview.",
    );
  }

  const verifier = generateVerifier();
  const challenge = await generateChallenge(verifier);
  const state = generateState();

  return isAndroidUA()
    ? androidOAuth(verifier, challenge, state)
    : desktopOAuth(verifier, challenge, state);
}

/** Restore a previously signed-in account from localStorage (call on app init). */
export function restoreGoogleAccount(): GoogleAccount | null {
  if (!loadTokens()) return null;
  return loadAccount();
}

export async function signOutGoogle(): Promise<void> {
  clearTokens();
}
