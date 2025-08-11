import { supabase } from "./supabaseClient";
import type { Bed, BedImage, Pin } from "../types/types";

export async function getBed(bedId: string): Promise<{
  bed: Bed;
  image: BedImage | null;
  pins: Pin[];
  publicUrl: string;
}> {
  const { data: bed, error: bedErr } = await supabase.from("beds").select("*").eq("id", bedId).single();
  
  if (bedErr) {
    console.error('Error fetching bed:', bedErr);
    throw bedErr;
  }

  // Choose the image: prefer bed.main_image_id if set, else latest
  let image: BedImage | null = null;
  if ((bed as Bed).main_image_id) {
    const { data: mainImage, error: mainErr } = await supabase
      .from("bed_images")
      .select("*")
      .eq("id", (bed as Bed).main_image_id as string)
      .maybeSingle();
    if (mainErr) throw mainErr;
    image = (mainImage ?? null) as BedImage | null;
  }
  if (!image) {
    const { data: latestImages, error: imgErr } = await supabase
      .from("bed_images")
      .select("*")
      .eq("bed_id", bedId)
      .order("created_at", { ascending: false })
      .limit(1);
    if (imgErr) throw imgErr;
    image = (latestImages?.[0] ?? null) as BedImage | null;
  }

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