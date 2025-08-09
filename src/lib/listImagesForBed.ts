import { supabase } from "./supabaseClient";
import type { BedImage } from "../types/types";

export async function listImagesForBed(bedId: string): Promise<BedImage[]> {
  const { data, error } = await supabase
    .from("bed_images")
    .select("*")
    .eq("bed_id", bedId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return (data ?? []) as BedImage[];
}