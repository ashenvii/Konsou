import { Button } from "@/components/ui/Button";
import { Section, Row, SettingsSubPage } from "@/components/settings/parts";
import { useAuthStore } from "@/lib/store/authStore";

export function AccountSettings() {
  const account = useAuthStore((s) => s.account);
  const connect = useAuthStore((s) => s.connect);
  const connecting = useAuthStore((s) => s.connecting);

  return (
    <SettingsSubPage title="Account">
      <Section title="Google account">
        <Row
          label={account ? account.name : "Not signed in"}
          hint={
            account
              ? account.email
              : "Sync your list across devices with Google Drive"
          }
        >
          {account ? (
            <Button variant="ghost" onClick={() => void useAuthStore.getState().disconnect()}>
              Sign out
            </Button>
          ) : (
            <Button variant="secondary" onClick={() => void connect()} disabled={connecting}>
              {connecting ? "Connecting…" : "Connect Google"}
            </Button>
          )}
        </Row>
      </Section>

      <Section>
        <Row
          label="What syncing does"
          hint="Your list is backed up to a private folder in your own Google Drive and merged across every device you sign in on. Konsou never sees your Google password, and there's no Konsou account."
        />
      </Section>
    </SettingsSubPage>
  );
}
