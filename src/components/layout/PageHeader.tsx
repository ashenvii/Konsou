import type { ReactNode } from "react";
import { ChevronLeft } from "lucide-react";
import { Icon } from "@/components/ui/Icon";

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  right?: ReactNode;
  /** When set, a back chevron is shown to the left of the title. */
  onBack?: () => void;
}

export function PageHeader({ title, subtitle, right, onBack }: PageHeaderProps) {
  return (
    <header className="k-pageheader">
      {onBack && (
        <button
          type="button"
          className="k-pageheader__back"
          onClick={onBack}
          aria-label="Back"
        >
          <Icon icon={ChevronLeft} size={22} />
        </button>
      )}
      <div className="k-pageheader__titles">
        <h1 className="k-pageheader__title">{title}</h1>
        {subtitle && <p className="k-pageheader__subtitle">{subtitle}</p>}
      </div>
      {right && <div className="k-pageheader__right">{right}</div>}
    </header>
  );
}
