// App version, injected from package.json "version" at build time via the
// __APP_VERSION__ define in vite.config.ts. Bump package.json and everything
// that shows or reports a version follows; nothing hardcodes it.
declare const __APP_VERSION__: string;

export const APP_VERSION = __APP_VERSION__;
