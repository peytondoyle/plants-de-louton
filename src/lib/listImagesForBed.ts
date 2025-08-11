import { supabase } from "./supabaseClient";
import type { BedImage } from "../types/types";
// @ts-expect-error exifr types may be missing in this environment
import exifr from "exifr";

export async function listImagesForBed(bedId: string): Promise<BedImage[]> {
  const { data, error } = await supabase
    .from("bed_images")
    .select("*")
    .eq("bed_id", bedId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  const images = (data ?? []) as BedImage[];

  // Enrich with EXIF date if missing (best-effort)
  await Promise.all(
    images.map(async (img) => {
      // If we already stored exif_date (optional future column), skip; else try to read from file
      if ((img as any).exif_date) return;
      try {
        const { data: pub } = supabase.storage.from("plant-images").getPublicUrl(img.image_path);
        const url = pub.publicUrl;
        if (!url) return;
        const tags = await exifr.parse(url, { tiff: true, ifd0: true, exif: true, pick: ["DateTimeOriginal", "CreateDate"] });
        const dt = (tags?.DateTimeOriginal as Date) || (tags?.CreateDate as Date);
        if (dt) (img as any).exif_date = dt.toISOString();
      } catch {
        // ignore if EXIF unavailable
      }
    })
  );

  return images;
}