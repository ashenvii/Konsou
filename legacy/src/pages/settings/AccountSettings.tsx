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
            // While waiting on the browser the button flips to Cancel, so an
            // abandoned sign-in never strands the page on a dead spinner.
            <Button
              variant="secondary"
              onClick={() =>
                connecting
                  ? useAuthStore.getState().cancelConnect()
                  : void connect()
              }
            >
              {connecting ? "Cancel" : "Connect Google"}
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
