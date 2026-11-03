import { Button } from "@/components/ui/Button";
import { Section, Row, SettingsSubPage, Toggle } from "@/components/settings/parts";
import { useNotificationStore } from "@/lib/store/notificationStore";
import { useSettingsStore } from "@/lib/store/settingsStore";

export function NotificationsSettings() {
  const settings = useSettingsStore();
  const restoreDismissed = useNotificationStore((s) => s.restoreDismissed);

  return (
    <SettingsSubPage title="Notifications">
      <Section title="Sequel radar">
        <Row label="Sequel notifications" hint="Scan completed anime for new seasons">
          <Toggle on={settings.sequelNotifications} onChange={settings.setSequelNotifications} />
        </Row>
        <Row label="Dismissed alerts" hint="Bring back alerts you've cleared">
          <Button variant="ghost" onClick={() => void restoreDismissed()}>
            Restore all
          </Button>
        </Row>
      </Section>
    </SettingsSubPage>
  );
}
