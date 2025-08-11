import { useEffect, useState } from "react";
import { getPinMedia } from "../../lib/pinMedia";
import "./PlantGalleryStrip.css";

type Props = { pinId: string; onOpen: () => void };

export default function PinGalleryStrip({ pinId, onOpen }: Props) {
  const [urls, setUrls] = useState<string[]>([]);
  useEffect(() => {
    let cancel = false;
    (async () => {
      try {
        const media = await getPinMedia(pinId);
        if (!cancel) setUrls(media.slice(0, 3).map(m => m.url));
      } catch {
        // ignore fetch errors
      }
    })();
    return () => { cancel = true; };
  }, [pinId]);

  return (
    <div className="pg-strip">
      {urls.map((u, i) => (
        <button key={i} className="pg-thumb" onClick={onOpen} aria-label="Open pin photos">
          <img src={u} alt="Pin media thumbnail" loading="lazy" />
        </button>
      ))}
    </div>
  );
}


