// App version, injected from package.json "version" at build time via the
// __APP_VERSION__ define in vite.config.ts. Bump package.json and everything
// that shows or reports a version follows; nothing hardcodes it.
declare const __APP_VERSION__: string;

export const APP_VERSION = __APP_VERSION__;

// The app's display name, injected from src-tauri/tauri.conf.json
// "productName" at build time via the __APP_NAME__ define. Anything that says
// the app's name out loud to a person reads it from here — the update notice
// most of all, since "Update for Konsou available" is a sentence that has to
// survive a rename without anyone remembering to grep for it.
declare const __APP_NAME__: string;

export const APP_NAME = __APP_NAME__;
