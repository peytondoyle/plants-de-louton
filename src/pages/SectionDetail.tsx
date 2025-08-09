// src/pages/SectionDetail.tsx
import { useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import ImageUploader from "../components/ImageUploader";
import PinDropper from "../components/PinDropper";
import { getPinsBySection } from "../lib/getPinsBySection";
import type { PlantPin } from "../types/types";

export default function SectionDetail() {
  const { slug } = useParams();
  const section = slug ?? "";

  // legacy list (plant_pins)
  const [legacyPins, setLegacyPins] = useState<PlantPin[]>([]);
  const [legacyLoading, setLegacyLoading] = useState(true);

  // new pinboard context (beds + pins)
  const [ctx, setCtx] = useState<{
    bedId: string;
    section: string;
    bedName: string;
    imageUrl: string;
  } | null>(null);

  useEffect(() => {
    if (!section) return;
    (async () => {
      setLegacyLoading(true);
      const data = await getPinsBySection(section);
      setLegacyPins(data);
      setLegacyLoading(false);
    })();
  }, [section]);

  return (
    <div className="app-root">
      <h1 className="text-3xl font-bold text-center mb-6 capitalize">
        {section.replace("-", " ")}
      </h1>

      {/* New flow: upload image -> drop pins (Supabase beds/pins) */}
      {!ctx && (
        <div className="pinboard-wrap" style={{ padding: 16, marginBottom: 16 }}>
          <p className="hint">Start a new bed for this section.</p>
          <ImageUploader
            initialSection={section}
            onReady={({ bed, publicUrl }) =>
              setCtx({
                bedId: bed.id,
                section: bed.section,
                bedName: bed.name,
                imageUrl: publicUrl,
              })
            }
          />
        </div>
      )}

      {ctx && (
        <>
          <PinDropper
            bedId={ctx.bedId}
            imageUrl={ctx.imageUrl}
            section={ctx.section}
            bedName={ctx.bedName}
          />
          <div style={{ display: "flex", gap: 8, justifyContent: "center", marginTop: 8 }}>
            <button className="btn ghost" onClick={() => setCtx(null)}>
              Upload a different image / bed
            </button>
          </div>
        </>
      )}

      {/* Legacy gallery (plant_pins) */}
      <div className="mt-8">
        <h2 className="text-xl font-semibold mb-3">Existing pins (legacy)</h2>
        {legacyLoading ? (
          <p className="text-center mt-4">Loading…</p>
        ) : legacyPins.length === 0 ? (
          <p className="text-gray-500">No pins found for this section.</p>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
            {legacyPins.map((pin) => (
              <div
                key={pin.id}
                className="rounded-lg shadow bg-white p-2 flex flex-col items-center"
              >
                {pin.image_url && (
                  <img
                    src={pin.image_url}
                    alt={pin.plant_name}
                    className="w-full h-32 object-cover rounded"
                  />
                )}
                <p className="mt-2 font-semibold text-center">{pin.plant_name}</p>
                {pin.detailed_name && (
                  <p className="text-sm text-gray-500 text-center">{pin.detailed_name}</p>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}