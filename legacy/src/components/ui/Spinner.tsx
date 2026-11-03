interface SpinnerProps {
  size?: number;
  className?: string;
}

export function Spinner({ size = 18, className }: SpinnerProps) {
  return (
    <span
      className={`k-spinner${className ? ` ${className}` : ""}`}
      style={{ width: size, height: size }}
      role="progressbar"
      aria-label="Loading"
    />
  );
}
