/** OAuth token + account persistence. Stored in localStorage for now; keychain is a v1.1 upgrade. */

const TOKENS_KEY = "konsou.google.tokens";
const ACCOUNT_KEY = "konsou.google.account";

export interface GoogleTokens {
  access_token: string;
  refresh_token: string;
  /** Unix ms timestamp when the access token expires. */
  expires_at: number;
  scope: string;
}

export interface StoredAccount {
  name: string;
  email: string;
  avatarUrl: string | null;
}

export function saveTokens(tokens: GoogleTokens): void {
  localStorage.setItem(TOKENS_KEY, JSON.stringify(tokens));
}

export function loadTokens(): GoogleTokens | null {
  const raw = localStorage.getItem(TOKENS_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as GoogleTokens;
  } catch {
    return null;
  }
}

export function clearTokens(): void {
  localStorage.removeItem(TOKENS_KEY);
  localStorage.removeItem(ACCOUNT_KEY);
}

/** Returns true if the access token expires within 60 seconds. */
export function isExpired(tokens: GoogleTokens): boolean {
  return Date.now() > tokens.expires_at - 60_000;
}

export function saveAccount(account: StoredAccount): void {
  localStorage.setItem(ACCOUNT_KEY, JSON.stringify(account));
}

export function loadAccount(): StoredAccount | null {
  const raw = localStorage.getItem(ACCOUNT_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as StoredAccount;
  } catch {
    return null;
  }
}
