import { supabase } from "./supabaseClient";
import type { Bed, BedImage, Pin } from "../types/types";

export async function getBed(bedId: string): Promise<{
  bed: Bed;
  image: BedImage | null;
  pins: Pin[];
  publicUrl: string;
}> {
  const { data: bed, error: bedErr } = await supabase.from("beds").select("*").eq("id", bedId).single();
  if (bedErr) throw bedErr;

  const { data: images, error: imgErr } = await supabase
    .from("bed_images")
    .select("*")
    .eq("bed_id", bedId)
    .order("created_at", { ascending: false })
    .limit(1);
  if (imgErr) throw imgErr;

  const image = (images?.[0] ?? null) as BedImage | null;

  const { data: pins, error: pinErr } = await supabase
    .from("pins")
    .select("*")
    .eq("bed_id", bedId)
    .order("created_at", { ascending: true });
  if (pinErr) throw pinErr;

  let publicUrl = "";
  if (image?.image_path) {
    const { data } = supabase.storage.from("plant-images").getPublicUrl(image.image_path);
    publicUrl = data.publicUrl;
  }

  return { bed: bed as Bed, image, pins: (pins ?? []) as Pin[], publicUrl };
}