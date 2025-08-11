import { supabase } from "./supabaseClient";

export async function getPlantPin(pinId: string): Promise<{ id: string; image_url: string | null } | null> {
  const { data, error } = await supabase
    .from("plant_pins")
    .select("id,image_url")
    .eq("id", pinId)
    .maybeSingle();
  if (error) throw error;
  return data ?? null;
}

export async function setPlantPinFeaturedUrl(pinId: string, imageUrl: string): Promise<void> {
  const { error } = await supabase
    .from("plant_pins")
    .update({ image_url: imageUrl })
    .eq("id", pinId);
  if (error) throw error;
}



