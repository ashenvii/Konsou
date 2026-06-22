import type { ReactNode } from "react";

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  right?: ReactNode;
}

export function PageHeader({ title, subtitle, right }: PageHeaderProps) {
  return (
    <header className="k-pageheader">
      <div className="k-pageheader__titles">
        <h1 className="k-pageheader__title">{title}</h1>
        {subtitle && <p className="k-pageheader__subtitle">{subtitle}</p>}
      </div>
      {right && <div className="k-pageheader__right">{right}</div>}
    </header>
  );
}
