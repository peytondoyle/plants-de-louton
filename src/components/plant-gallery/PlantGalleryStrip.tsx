import { useEffect, useState } from "react";
import { getPlantMedia } from "../../lib/plantMedia";
import type { PlantMedia } from "../../types/types";
import "./PlantGalleryStrip.css";

export default function PlantGalleryStrip({ plantId, onOpen }: { plantId: string; onOpen: () => void }) {
  const [items, setItems] = useState<PlantMedia[]>([]);
  useEffect(() => {
    let cancel = false;
    (async () => {
      try {
        const media = await getPlantMedia(plantId);
        if (!cancel) setItems(media.slice(0, 3));
      } catch {
        // ignore
      }
    })();
    return () => { cancel = true; };
  }, [plantId]);

  return (
    <div className="pg-strip">
      {items.map((m) => (
        <button key={m.id} className="pg-thumb" onClick={onOpen} aria-label="Open plant gallery">
          <img src={m.url} alt="Plant media thumbnail" loading="lazy" />
        </button>
      ))}
      <button className="pg-add" onClick={onOpen} aria-label="Add plant photo">+</button>
    </div>
  );
}


