import { useEffect, useMemo, useRef, useState } from "react";
import { supabase } from "../lib/supabaseClient";
import { mapSections } from "../data/mapSections";
import type { Bed, BedImage } from "../types/types";
import { v4 as uuidv4 } from "uuid";

const BUCKET = "plant-images";

type Props = {
  initialSection?: string;
  onReady?: (args: { bed: Bed; image: BedImage | null; publicUrl: string }) => void;
};

export default function ImageUploader({ initialSection = "", onReady }: Props) {
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [section, setSection] = useState<string>(initialSection);
  const [bedName, setBedName] = useState<string>("");
  const [showModal, setShowModal] = useState(false);
  const [busy, setBusy] = useState(false);
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [existingBeds, setExistingBeds] = useState<Bed[]>([]);
  const inputRef = useRef<HTMLInputElement | null>(null);

  // open picker -> show modal
  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImageFile(file);
    setShowModal(true);
  };

  // fetch existing beds for section so we don’t duplicate
  useEffect(() => {
    if (!section) { setExistingBeds([]); return; }
    let cancel = false;
    (async () => {
      const { data, error } = await supabase
        .from("beds")
        .select("*")
        .eq("section", section)
        .order("created_at", { ascending: true });
      if (!cancel) setExistingBeds((error ? [] : (data as Bed[])) || []);
    })();
    return () => { cancel = true; };
  }, [section]);

  const duplicate = useMemo(
    () => !!existingBeds.find(b => b.name.trim().toLowerCase() === bedName.trim().toLowerCase()),
    [existingBeds, bedName]
  );

  const canUpload = useMemo(
    () => Boolean(imageFile && section && bedName.trim() && !busy && !duplicate),
    [imageFile, section, bedName, busy, duplicate]
  );

  // helpers
  async function getOrCreateBed(sec: string, name: string): Promise<Bed> {
    const { data: existing } = await supabase
      .from("beds")
      .select("*")
      .eq("section", sec)
      .eq("name", name)
      .maybeSingle();
    if (existing) return existing as Bed;

    const { data, error } = await supabase
      .from("beds")
      .insert({ section: sec, name })
      .select("*")
      .single();
    if (error || !data) throw error ?? new Error("Failed to create bed");
    return data as Bed;
  }

  function slugify(s: string) {
    return s.toLowerCase().trim().replace(/[^\w-]+/g, "-").replace(/-+/g, "-");
  }
  function fileExt(f: File) {
    const n = f.name; const dot = n.lastIndexOf("."); return dot >= 0 ? n.slice(dot + 1) : "jpg";
  }
  function readImageSize(file: File): Promise<{ width: number; height: number }> {
    return new Promise((resolve, reject) => {
      const fr = new FileReader();
      fr.onload = () => { const img = new Image(); img.onload = () => resolve({ width: img.width, height: img.height }); img.onerror = reject; img.src = fr.result as string; };
      fr.onerror = reject;
      fr.readAsDataURL(file);
    });
  }

  async function getLatestImage(bedId: string): Promise<{ image: BedImage | null; publicUrl: string }> {
    const { data, error } = await supabase
      .from("bed_images")
      .select("*")
      .eq("bed_id", bedId)
      .order("created_at", { ascending: false })
      .limit(1);
    if (error) throw error;
    const img = (data?.[0] as BedImage) ?? null;
    if (!img) return { image: null, publicUrl: "" };
    const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(img.image_path);
    return { image: img, publicUrl: pub.publicUrl };
  }

  // choose an existing bed (no new upload needed)
  const useExistingBed = async (b: Bed) => {
    setBusy(true);
    try {
      const { image, publicUrl } = await getLatestImage(b.id);
      setImageUrl(publicUrl || null);
      setShowModal(false);
      setImageFile(null);
      if (inputRef.current) inputRef.current.value = "";
      onReady?.({ bed: b, image, publicUrl });
    } catch (e: unknown) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      alert(errorMessage);
    } finally {
      setBusy(false);
    }
  };

  // upload new image for a (new or existing) bed
  const upload = async () => {
    if (!imageFile || !section || !bedName.trim()) return;
    setBusy(true);
    try {
      const bed = await getOrCreateBed(section, bedName.trim());
      const { width, height } = await readImageSize(imageFile);
      const path = `${slugify(section)}/${slugify(bedName)}/${uuidv4()}.${fileExt(imageFile)}`;

      const { error: upErr } = await supabase.storage.from(BUCKET).upload(path, imageFile, {
        cacheControl: "3600",
        upsert: false,
        contentType: imageFile.type || "image/jpeg",
      });
      if (upErr) throw upErr;

      const { data, error } = await supabase
        .from("bed_images")
        .insert({ bed_id: bed.id, image_path: path, width, height })
        .select("*")
        .single();
      if (error || !data) throw error ?? new Error("Failed to save bed image");
      const image = data as BedImage;

      const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(path);
      const publicUrl = pub.publicUrl;

      setImageUrl(publicUrl);
      setShowModal(false);
      setImageFile(null);
      if (inputRef.current) inputRef.current.value = "";
      onReady?.({ bed, image, publicUrl });
    } catch (e: unknown) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      alert(errorMessage);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="p-4">
      <input ref={inputRef} type="file" accept="image/*" onChange={handleImageSelect} />

      {showModal && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50" onClick={() => !busy && setShowModal(false)}>
          <div className="bg-white rounded-lg p-6 w-[520px] max-w-[95vw] shadow-lg space-y-4" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-lg font-semibold">Assign Section & Name Bed</h2>

            <div className="grid gap-3">
              <select
                className="w-full p-2 border rounded"
                value={section}
                onChange={(e) => setSection(e.target.value)}
                disabled={busy}
              >
                <option value="">Select Section</option>
                {mapSections.map((s) => (
                  <option key={s.slug} value={s.slug}>{s.label}</option>
                ))}
              </select>

              <input
                className="w-full p-2 border rounded"
                placeholder="e.g., Shed bed"
                value={bedName}
                onChange={(e) => setBedName(e.target.value)}
                disabled={busy}
              />
              {duplicate && (
                <p className="text-sm text-red-600">
                  A bed named <b>{bedName}</b> already exists. Pick it from the list below or choose a different name.
                </p>
              )}
            </div>

            {/* Existing beds for this section */}
            <div className="border rounded p-3 max-h-48 overflow-auto">
              <div className="text-sm font-medium mb-2">Existing beds in this section</div>
              {existingBeds.length === 0 ? (
                <div className="text-sm text-gray-500">None yet.</div>
              ) : (
                <ul className="space-y-2">
                  {existingBeds.map((b) => (
                    <li key={b.id} className="flex items-center justify-between gap-2">
                      <span className="text-sm">{b.name}</span>
                      <button
                        className="px-2 py-1 text-sm rounded bg-gray-800 text-white"
                        onClick={() => {
                          void (async () => {
                            setBusy(true);
                            try {
                              const { image, publicUrl } = await getLatestImage(b.id);
                              setImageUrl(publicUrl || null);
                              setShowModal(false);
                              setImageFile(null);
                              if (inputRef.current) inputRef.current.value = "";
                              onReady?.({ bed: b, image, publicUrl });
                            } catch (e: unknown) {
                              const errorMessage = e instanceof Error ? e.message : String(e);
                              alert(errorMessage);
                            } finally {
                              setBusy(false);
                            }
                          })();
                        }}
                        disabled={busy}
                      >
                        Use this bed
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </div>

            <div className="flex gap-2 justify-end">
              <button className="btn ghost" onClick={() => setShowModal(false)} disabled={busy}>Cancel</button>
              <button
                className={`btn ${canUpload ? "primary" : "disabled"}`}
                onClick={upload}
                disabled={!canUpload}
              >
                {busy ? "Uploading…" : "Upload Image & Continue"}
              </button>
            </div>
          </div>
        </div>
      )}

      {imageUrl && (
        <div className="mt-4">
          <h3 className="font-medium">Uploaded Image:</h3>
          <img
            src={imageUrl}
            alt={`${section} - ${bedName}`}
            className="uploaded-image"
          />
        </div>
      )}
    </div>
  );
}