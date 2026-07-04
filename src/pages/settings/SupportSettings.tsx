import { Code2, Coffee, Heart, Share2, Star } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Section, Row, SettingsSubPage } from "@/components/settings/parts";
import { Text } from "@/components/ui/Text";
import { openExternal } from "@/lib/openExternal";
import { toast } from "@/lib/store/toastStore";

const KOFI_URL = (import.meta.env.VITE_KOFI_URL as string | undefined) ?? "https://ko-fi.com";
const GITHUB_URL = (import.meta.env.VITE_GITHUB_URL as string | undefined) ?? "https://github.com";

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
      <div className="k-support__hero">
        <span className="k-support__heroicon">
          <Icon icon={Heart} size={26} />
        </span>
        <Text as="h2" size="lg" weight={700} className="k-support__herotitle">
          Free, and staying that way
        </Text>
        <Text size="sm" color="secondary" className="k-support__herotext">
          Konsou has no ads and no premium tier. It's built and given away for
          free. If it earns a place on your home screen, chipping in keeps it
          running and pays for what comes next.
        </Text>
        <Button variant="primary" onClick={() => void openExternal(KOFI_URL)}>
          <Icon icon={Coffee} size={16} /> Buy me a coffee
        </Button>
      </div>

      <Section title="More ways to help">
        <Row label="Tip on Ko-fi" hint="One-off or monthly, any amount helps">
          <Button variant="secondary" onClick={() => void openExternal(KOFI_URL)}>
            <Icon icon={Heart} size={15} color="var(--color-error)" /> Open
          </Button>
        </Row>
        <Row label="Contribute on GitHub" hint="Report bugs, suggest features, or send a pull request">
          <Button variant="secondary" onClick={() => void openExternal(GITHUB_URL)}>
            <Icon icon={Code2} size={15} /> Open
          </Button>
        </Row>
        <Row label="Star the repo" hint="A quick way to help others find Konsou">
          <Button variant="secondary" onClick={() => void openExternal(GITHUB_URL)}>
            <Icon icon={Star} size={15} /> Star
          </Button>
        </Row>
        <Row label="Share Konsou" hint="Tell a friend who's still juggling spreadsheets">
          <Button variant="secondary" onClick={() => void share()}>
            <Icon icon={Share2} size={15} /> Share
          </Button>
        </Row>
      </Section>
    </SettingsSubPage>
  );
}
