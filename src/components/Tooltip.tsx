import { useId, useState } from "react";

export default function Tooltip({
  label,
  children,
}: { label: string; children: React.ReactNode }) {
  const id = useId();
  const [open, setOpen] = useState(false);
  return (
    <span
      className="tt-wrap"
      onMouseEnter={() => setOpen(true)}
      onMouseLeave={() => setOpen(false)}
      onFocus={() => setOpen(true)}
      onBlur={() => setOpen(false)}
    >
      <button
        className="pill pill--icon"
        aria-describedby={open ? id : undefined}
      >
        {children}
      </button>
      <span
        id={id}
        role="tooltip"
        className={`tt ${open ? "open" : ""}`}
      >
        Click the image to add a pin. Click a pin to edit.
        Use the thumbnails above to switch images.
      </span>
    </span>
  );
}