import React, { useEffect, useMemo, useState } from "react";
import Tooltip from "./Tooltip";

function luma(r: number, g: number, b: number) { return 0.2126*r + 0.7152*g + 0.0722*b; }

type Props = {
  imgEl: HTMLImageElement | null;
  containerEl: HTMLElement | null;
  timestamp: string;
  corner?: "br" | "bl";
};

export default function MainImageTooltip({ imgEl, containerEl, timestamp, corner = "br" }: Props) {
  const [light, setLight] = useState(false);

  useEffect(() => {
    let decided = false;
    try {
      if (imgEl && imgEl.complete && imgEl.naturalWidth > 0) {
        const W = 24, H = 24, c = document.createElement("canvas");
        const ctx = c.getContext("2d", { willReadFrequently: true });
        if (ctx) {
          c.width = W; c.height = H;
          const sx = Math.max(0, imgEl.naturalWidth - W - 4);
          const sy = Math.max(0, imgEl.naturalHeight - H - 4);
          ctx.drawImage(imgEl, sx, sy, W, H, 0, 0, W, H);
          const data = ctx.getImageData(0, 0, W, H).data;
          let sum = 0, n = 0; for (let i = 0; i < data.length; i += 4) { sum += luma(data[i], data[i+1], data[i+2]); n++; }
          setLight(sum / n > 150);
          decided = true;
        }
      }
    } catch {/* ignore CORS */}

    if (!decided && containerEl) {
      const bg = getComputedStyle(containerEl).backgroundColor;
      const m = bg.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/i);
      if (m) setLight(luma(+m[1], +m[2], +m[3]) > 150);
    }
  }, [imgEl, containerEl, timestamp]);

  const pos = useMemo(() => (corner === "bl" ? { left: 10, bottom: 10 } : { right: 10, bottom: 10 }), [corner]);

  return (
    <div className="tt-wrap tt-wrap--abs" style={{ position: "absolute", ...pos }}>
      <Tooltip label={`Captured ${timestamp}`}>
        <span>i</span>
      </Tooltip>
      <span className={`tt tt--up ${light ? "tt--light" : ""}`} role="tooltip">
        Captured {timestamp}
      </span>
    </div>
  );
}


