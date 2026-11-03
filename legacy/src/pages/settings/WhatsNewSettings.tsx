import { useState } from "react";
import { History, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { EmptyState } from "@/components/ui/EmptyState";
import { SettingsSubPage } from "@/components/settings/parts";
import { UpdateBlock } from "@/components/settings/UpdateBlock";
import { Text } from "@/components/ui/Text";
import { ChangelogBody } from "@/components/WhatsNew";
import { getBundledChangelog } from "@/lib/changelog";
import { APP_VERSION } from "@/lib/updater";

/** How many more versions each "Show older versions" tap reveals. */
const HISTORY_PAGE = 3;

/**
 * The release history, as its own page.
 *
 * It used to be a section wedged into About, which made three different jobs
 * (what this app is, what changed, how to help) share one scroll. What changed
 * is its own question with its own answer, so it gets its own door — the same
 * split the sidebar's shortcuts assume.
 *
 * The changelog ships inside the bundle (see lib/changelog), so this page works
 * offline and always matches the version actually installed.
 */
export function WhatsNewSettings() {
  const changelog = getBundledChangelog();
  // Entry 0 is always open; the rest reveal a page at a time.
  const [shown, setShown] = useState(1);

  return (
    <SettingsSubPage title="What's new">
      {/* Above the notes, always. This page answers two questions that belong
          together and used to live in different menus: is there a newer build,
          and what is in it. The block states the first even when the answer is
          "you are current", because a page you arrive at to check for an update
          has to say so rather than leaving you to infer it from the absence of
          a banner. */}
      <UpdateBlock />

      {changelog.length === 0 ? (
        <EmptyState
          title="No release notes yet"
          subtitle="Once Konsou ships an update, what changed shows up here."
        />
      ) : (
        <>
          <div className="k-whatsnew__lede">
            <Icon icon={Sparkles} size={16} color="var(--live-ink)" />
            <Text size="sm" color="secondary">
              Everything below shipped in your release or the ones before it.
            </Text>
          </div>

          <div className="k-releases">
            {changelog.slice(0, shown).map((entry) => (
              <article key={entry.version} className="k-release">
                <header className="k-release__head">
                  <span className="k-release__version">v{entry.version}</span>
                  {entry.date && <span className="k-release__date">{entry.date}</span>}
                  {entry.version === APP_VERSION && (
                    <span className="k-release__current">Installed</span>
                  )}
                </header>
                <ChangelogBody entry={entry} />
              </article>
            ))}
          </div>

          {shown < changelog.length && (
            <Button
              variant="secondary"
              onClick={() => setShown((n) => Math.min(n + HISTORY_PAGE, changelog.length))}
            >
              <Icon icon={History} size={15} /> Show older versions
            </Button>
          )}
        </>
      )}
    </SettingsSubPage>
  );
}
