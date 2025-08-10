import { useId, useState } from "react";

type Props = {
  label: string;
  children: React.ReactNode;
  placement?: "up" | "down";
  wrapClassName?: string;
  wrapStyle?: React.CSSProperties;
};

export default function Tooltip({ label, children, placement = "down", wrapClassName, wrapStyle }: Props) {
  const id = useId();
  const [open, setOpen] = useState(false);
  
  const ArrowIcon = () => (
    <svg
      width="12"
      height="6"
      viewBox="0 0 12 6"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className="tt-arrow"
    >
      {placement === "up" ? (
        // Arrow pointing up (for tooltips below content)
        <path
          d="M6 0L0 6H12L6 0Z"
          fill="currentColor"
        />
      ) : (
        // Arrow pointing down (for tooltips above content)
        <path
          d="M6 6L0 0H12L6 6Z"
          fill="currentColor"
        />
      )}
    </svg>
  );

  return (
    <span
      className={wrapClassName ?? "tt-wrap"}
      style={wrapStyle}
      onMouseEnter={() => setOpen(true)}
      onMouseLeave={() => setOpen(false)}
      onFocus={() => setOpen(true)}
      onBlur={() => setOpen(false)}
    >
      <button className="pill pill--icon" aria-describedby={open ? id : undefined}>
        {children}
      </button>
      <span
        id={id}
        role="tooltip"
        className={`tt ${placement === "up" ? "tt--up" : ""} ${open ? "open" : ""}`}
      >
        {label}
        <ArrowIcon />
      </span>
    </span>
  );
}