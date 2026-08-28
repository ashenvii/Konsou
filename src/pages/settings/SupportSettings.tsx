import { Code2, Coffee, Heart, Share2, Star } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { LinkRow, Section, SettingsSubPage } from "@/components/settings/parts";
import { openExternal } from "@/lib/openExternal";
import { toast } from "@/lib/store/toastStore";

const KOFI_URL = (import.meta.env.VITE_KOFI_URL as string | undefined) ?? "https://ko-fi.com";
const GITHUB_URL = (import.meta.env.VITE_GITHUB_URL as string | undefined) ?? "https://github.com";

/**
 * How to help keep Konsou going.
 *
 * The page opens on a tip plate: the thing you are actually being asked to do
 * gets to look like an offer, not like row four of a settings list. Everything
 * below it is a plain ruled row, so the one accent on the page is spent on the
 * one action — the same discipline the rest of the app follows with its
 * vermilion. The version this replaced had swung the other way: a glowing
 * gradient hero with a pulsing heart, which made asking for money the loudest
 * thing the app ever did.
 */
export function SupportSettings() {
  const share = async () => {
    const text = "Konsou, a free offline-first anime tracker with a sequel radar.";
    if (navigator.share) {
      try {
        await navigator.share({ title: "Konsou", text, url: GITHUB_URL });
      } catch {
        /* user dismissed the share sheet */
      }
      return;
    }
    try {
      await navigator.clipboard.writeText(GITHUB_URL);
      toast.success("Link copied to clipboard");
    } catch {
      void openExternal(GITHUB_URL);
    }
  };

  return (
    <SettingsSubPage title="Support Konsou">
      {/* The tip plate. Mounted like a specimen (keyline + photo-corners), so
          the ask reads as something offered rather than a banner. */}
      <section className="k-tip">
        <span className="k-tip__corners" aria-hidden>
          <i /><i /><i /><i />
        </span>
        <span className="k-tip__mark" aria-hidden>
          <Icon icon={Coffee} size={22} />
        </span>
        <h2 className="k-tip__title">Buy me a coffee</h2>
        <p className="k-tip__body">
          Konsou has no ads, no premium tier, and no unlock codes. It is built
          and given away for free. If it has earned a place on your home screen,
          a one-off tip keeps it running and pays for what comes next.
        </p>
        <button
          type="button"
          className="k-tip__action"
          onClick={() => void openExternal(KOFI_URL)}
        >
          <Icon icon={Heart} size={15} />
          Tip on Ko-fi
        </button>
        <p className="k-tip__foot">Any amount. One-off or monthly. No account needed.</p>
      </section>

      <Section title="Help without paying">
        <LinkRow
          icon={Code2}
          title="Contribute on GitHub"
          hint="Report bugs, suggest features, send a pull request"
          external
          onClick={() => void openExternal(GITHUB_URL)}
        />
        <LinkRow
          icon={Star}
          title="Star the repo"
          hint="A quick way to help other people find Konsou"
          external
          onClick={() => void openExternal(GITHUB_URL)}
        />
        <LinkRow
          icon={Share2}
          title="Share Konsou"
          hint="Tell a friend who is still juggling spreadsheets"
          onClick={() => void share()}
        />
      </Section>
    </SettingsSubPage>
  );
}
