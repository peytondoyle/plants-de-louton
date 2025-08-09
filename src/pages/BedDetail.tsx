import { useEffect, useState } from "react";
import { useNavigate, useParams, Link } from "react-router-dom";
import { getBed } from "../lib/getBeds";
import PinDropper from "../components/PinDropper";
import NewBedModal from "../components/NewBedModal"; // reuse for "Change image" path to upload to same bed
import type { Bed, BedImage } from "../types/types";
import { supabase } from "../lib/supabaseClient";
import { v4 as uuidv4 } from "uuid";

const BUCKET = "plant-images";

export default function BedDetail() {
  const { slug = "", bedId = "" } = useParams();
  const nav = useNavigate();

  const [bed, setBed] = useState<Bed | null>(null);
  const [imageUrl, setImageUrl] = useState("");
  const [loading, setLoading] = useState(true);

  async function refresh() {
    setLoading(true);
    try {
      const data = await getBed(bedId);
      setBed(data.bed);
      setImageUrl(data.publicUrl || "");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { void refresh(); }, [bedId]);

  // change image for this bed
  const onChangeImage = async (file: File) => {
    if (!bed) return;
    const path = `${bed.section}/${bed.name}/${uuidv4()}.${(file.name.split(".").pop() || "jpg")}`;
    const { error: upErr } = await supabase.storage.from(BUCKET).upload(path, file, {
      cacheControl: "3600",
      upsert: false,
      contentType: file.type || "image/jpeg",
    });
    if (upErr) return alert(upErr.message);
    const { error } = await supabase.from("bed_images").insert({ bed_id: bed.id, image_path: path });
    if (error) return alert(error.message);
    const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
    setImageUrl(data.publicUrl);
  };

  return (
    <div className="app-root">
      <div className="flex items-center justify-between mb-3">
        <h1 className="text-2xl font-semibold">{bed?.name ?? "Bed"}</h1>
        <div className="flex gap-2">
          <Link className="btn ghost" to={`/section/${slug}`}>Back to {slug.replace("-", " ")}</Link>
          <label className="btn">
            Change image
            <input type="file" accept="image/*" style={{ display: "none" }} onChange={(e) => e.target.files?.[0] && onChangeImage(e.target.files[0])} />
          </label>
        </div>
      </div>

      {loading ? (
        <p>Loading…</p>
      ) : !imageUrl ? (
        <div className="text-gray-500">This bed has no image yet. Use “Change image”.</div>
      ) : (
        <PinDropper bedId={bedId} imageUrl={imageUrl} section={slug} bedName={bed?.name ?? ""} />
      )}
    </div>
  );
}