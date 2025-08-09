import { useRef, useState } from "react";
import { supabase } from "../lib/supabaseClient";
import type { Bed, BedImage } from "../types/types";
import { v4 as uuidv4 } from "uuid";

const BUCKET = "plant-images";

export default function NewBedModal({
  section,
  onClose,
  onCreated,
}: {
  section: string;
  onClose: () => void;
  onCreated: (args: { bed: Bed; image: BedImage | null; publicUrl: string }) => void;
}) {
  const [bedName, setBedName] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [busy, setBusy] = useState(false);
  const inputRef = useRef<HTMLInputElement | null>(null);

  async function getOrCreateBed(name: string): Promise<Bed> {
    const { data: existing } = await supabase
      .from("beds").select("*").eq("section", section).eq("name", name).maybeSingle();
    if (existing) return existing as Bed;

    const { data, error } = await supabase.from("beds").insert({ section, name }).select("*").single();
    if (error || !data) throw error ?? new Error("Failed to create bed");
    return data as Bed;
  }

  function slug(s: string) { return s.toLowerCase().trim().replace(/[^\w\-]+/g, "-").replace(/\-+/g, "-"); }
  function ext(f: File) { const n = f.name; const i = n.lastIndexOf("."); return i >= 0 ? n.slice(i + 1) : "jpg"; }

  const create = async () => {
    if (!bedName.trim()) return;
    setBusy(true);
    try {
      const bed = await getOrCreateBed(bedName.trim());
      let image: BedImage | null = null;
      let publicUrl = "";

      if (file) {
        const path = `${slug(section)}/${slug(bedName)}/${uuidv4()}.${ext(file)}`;
        const { error: upErr } = await supabase.storage.from(BUCKET).upload(path, file, {
          cacheControl: "3600",
          upsert: false,
          contentType: file.type || "image/jpeg",
        });
        if (upErr) throw upErr;

        const { data, error } = await supabase
          .from("bed_images").insert({ bed_id: bed.id, image_path: path }).select("*").single();
        if (error || !data) throw error ?? new Error("Failed to save image");
        image = data as BedImage;

        publicUrl = supabase.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;
      }

      onCreated({ bed, image, publicUrl });
      onClose();
    } catch (e: any) {
      alert(e?.message ?? String(e));
    } finally {
      setBusy(false);
      if (inputRef.current) inputRef.current.value = "";
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 grid place-items-center z-50" onClick={onClose}>
      <div className="bg-white rounded-xl w-[520px] max-w-[92vw] p-5 space-y-3" onClick={(e) => e.stopPropagation()}>
        <h3 className="text-lg font-semibold">Add bed to “{section.replace("-", " ")}”</h3>
        <input className="w-full p-2 border rounded" placeholder="Bed name" value={bedName} onChange={(e) => setBedName(e.target.value)} />
        <input ref={inputRef} type="file" accept="image/*" onChange={(e) => setFile(e.target.files?.[0] ?? null)} />
        <div className="flex gap-2 justify-end">
          <button className="btn ghost" onClick={onClose} disabled={busy}>Cancel</button>
          <button className="btn primary" disabled={!bedName.trim() || busy} onClick={create}>
            {busy ? "Creating…" : "Create bed"}
          </button>
        </div>
      </div>
    </div>
  );
}