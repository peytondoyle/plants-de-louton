import { useEffect, useRef, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { getBed } from "../lib/getBeds";
import PinDropper from "../components/PinDropper";
import PinEditorDrawer from "../components/PinEditorDrawer";
import PinList from "../components/PinList";
import ImageHistory from "../components/ImageHistory";
import { listImagesForBed } from "../lib/listImagesForBed";
import type { Bed, BedImage, Pin } from "../types/types";
import { supabase } from "../lib/supabaseClient";
import { v4 as uuidv4 } from "uuid";
import PinsPanel from "../components/PinsPanel";



const BUCKET = "plant-images";

export default function BedDetail() {
  const { slug = "", bedId = "" } = useParams();

  const [bed, setBed] = useState<Bed | null>(null);
  const [imageUrl, setImageUrl] = useState("");
  const [imagePath, setImagePath] = useState<string | null>(null);
  const [pins, setPins] = useState<Pin[]>([]);
  const [images, setImages] = useState<BedImage[]>([]);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [draftInit, setDraftInit] = useState<Pin | { x: number; y: number } | undefined>(undefined);

  // Load initial bed + latest image + pins + history
  async function refresh() {
    const data = await getBed(bedId);
    setBed(data.bed);
    setImageUrl(data.publicUrl || "");
    setImagePath(data.image?.image_path ?? null);
    const hist = await listImagesForBed(bedId);
    setImages(hist);
  }

  useEffect(() => { void refresh(); }, [bedId]);

  // Change image for this bed
  const onChangeImage = async (file: File) => {
    if (!bed) return;
    const path = `${bed.section}/${bed.name}/${uuidv4()}.${(file.name.split(".").pop() || "jpg")}`;
    const { error: upErr } = await supabase.storage.from(BUCKET).upload(path, file, {
      cacheControl: "3600",
      upsert: false,
      contentType: file.type || "image/jpeg",
    });
    if (upErr) return alert(upErr.message);
    const { data, error } = await supabase.from("bed_images").insert({ bed_id: bed.id, image_path: path }).select("*").single();
    if (error) return alert(error.message);
    setImages((prev) => [data as BedImage, ...prev]);
    const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(path);
    setImageUrl(pub.publicUrl);
    setImagePath(path);
  };

  // Pin editor triggers
  const createAt = (pos: { x: number; y: number }) => { setDraftInit(pos); setDrawerOpen(true); };
  const editPin = (pin: Pin) => { setDraftInit(pin); setDrawerOpen(true); };

  // When drawer saves/deletes, update local list
  const onSaved = (pin: Pin) => {
    setPins((prev) => {
      const i = prev.findIndex((p) => p.id === pin.id);
      if (i >= 0) { const copy = prev.slice(); copy[i] = pin; return copy; }
      return [...prev, pin];
    });
  };
  const onDeleted = (id: string) => setPins((prev) => prev.filter((p) => p.id !== id));

  // Jump to a pin from the list by simulating a click: just center view visually
  const boardRef = useRef<HTMLDivElement | null>(null);

  return (
  <div className="app-root">
    <div className="page-header">
      {/* title */}
        <h1 className="page-title">{bed?.name ?? "Bed"}</h1>

        {/* small pill actions just under the title */}
        <div className="page-toolbar">
        <a className="pill pill--link" href={`/section/${slug}`}>
            Back to {slug?.replace("-", " ")}
        </a>

        <label className="pill" style={{ cursor: "pointer" }}>
            Change image
            <input
            type="file"
            accept="image/*"
            onChange={(e) => e.target.files?.[0] && onChangeImage(e.target.files[0])}
            />
        </label>
        </div>
    </div>

    {/* Image history (kept full width above grid) */}
    {/* image history strip (optional) */}
{images.length > 0 && (
  <ImageHistory
    images={images}
    activePath={imagePath}
    onSelect={(img, url) => { setImagePath(img.image_path); setImageUrl(url); }}
  />
)}

<div className="page-grid">
  <div className="left-col">
    {imageUrl ? (
      <div className="pinboard-stage">
        <div className="image-shell card">
          <PinDropper
            bedId={bedId}
            imageUrl={imageUrl}
            section={slug}
            bedName={bed?.name ?? ""}
            onCreateAt={(pos) => { setDraftInit(pos); setDrawerOpen(true); }}
            onEditPin={(pin) => { setDraftInit(pin); setDrawerOpen(true); }}
            onPinsChange={setPins}
            useExternalEditor
            showInlineHint   // <-- PinDropper shows the ONE hint
          />
        </div>
      </div>
    ) : (
      <div className="empty">This bed has no image yet. Use “Change image”.</div>
    )}
  </div>

  <aside className="sidebar">
    <PinsPanel
      pins={pins}
      onAdd={() => { setDraftInit({ x: 0.5, y: 0.5 }); setDrawerOpen(true); }}
      onOpen={(pin) => { setDraftInit(pin); setDrawerOpen(true); }}
    />
    <div className="card" style={{ padding:10 }}>
      <div className="panel-title" style={{ marginBottom:6 }}>Quick help</div>
      <div style={{ fontSize:13, color:"#6b7280", lineHeight:1.4 }}>
        Click the image to add a pin. Click a pin to edit.
        Use the thumbnails above to switch images.
      </div>
    </div>
  </aside>
</div>

<PinEditorDrawer
  open={drawerOpen}
  onClose={() => setDrawerOpen(false)}
  bedId={bedId}
  initial={draftInit}
  onSaved={(pin) => setPins((prev) => {
    const i = prev.findIndex((p) => p.id === pin.id);
    if (i >= 0) { const c = prev.slice(); c[i] = pin; return c; }
    return [...prev, pin];
  })}
  onDeleted={(id) => setPins((prev) => prev.filter((p) => p.id !== id))}
/>
  </div>
);
}