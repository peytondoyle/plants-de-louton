import React, { useMemo } from "react";
import Tooltip from "./Tooltip/Tooltip";

type Props = {
  timestamp: string;
  corner?: "br" | "bl";
};

export default function MainImageTooltip({ timestamp, corner = "br" }: Props) {
  const pos = useMemo(() => (corner === "bl" ? { left: 10, bottom: 10 } : { right: 10, bottom: 10 }), [corner]);

  return (
    <div style={{ position: "absolute", ...pos }}>
      <Tooltip
        content={`Captured ${timestamp}`}
        placement="top"
        autoTheme
      >
        <button className="pill pill--icon" aria-label="Captured info">
          <svg aria-hidden="true" width="14" height="14" viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="11" fill="currentColor" opacity=".08"/>
            <path d="M12 8.5a1.25 1.25 0 1 1 0-2.5 1.25 1.25 0 0 1 0 2.5Zm-1.1 2.7h2.2v6.3h-2.2z" fill="currentColor"/>
          </svg>
        </button>
      </Tooltip>
    </div>
  );
}


