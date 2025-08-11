import { supabase } from "./supabaseClient";
import type { PlantMedia } from "../types/types";
import { v4 as uuidv4 } from "uuid";

const BUCKET = "plant-media";

export async function getPlantMedia(plantId: string): Promise<PlantMedia[]> {
  const { data, error } = await supabase
    .from("plant_media")
    .select("*")
    .eq("plant_id", plantId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  const list = (data ?? []) as PlantMedia[];
  return list.map((m) => {
    const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(m.storage_path);
    return { ...m, url: pub.publicUrl };
  });
}

export async function uploadPlantMedia(
  plantId: string,
  file: File,
  link?: { imageId?: string; pinId?: string; capturedAt?: string; caption?: string }
): Promise<void> {
  const ext = (file.name.split(".").pop() || "jpg").toLowerCase();
  const path = `${plantId}/${uuidv4()}.${ext}`;
  const { error: upErr } = await supabase.storage
    .from(BUCKET)
    .upload(path, file, {
      cacheControl: "3600",
      upsert: false,
      contentType: file.type || "image/jpeg",
    });
  if (upErr) throw upErr;

  const { error } = await supabase
    .from("plant_media")
    .insert({
      plant_id: plantId,
      storage_path: path,
      image_id: link?.imageId ?? null,
      pin_id: link?.pinId ?? null,
      captured_at: link?.capturedAt ?? null,
      caption: link?.caption ?? null,
    });
  if (error) throw error;
}

export async function deletePlantMedia(mediaId: string): Promise<void> {
  // Fetch to get path
  const { data, error } = await supabase
    .from("plant_media")
    .select("id, storage_path")
    .eq("id", mediaId)
    .maybeSingle();
  if (error) throw error;
  const path = (data as { storage_path: string } | null)?.storage_path;
  if (!path) return;

  const { error: sErr } = await supabase.storage.from(BUCKET).remove([path]);
  if (sErr) throw sErr;

  const { error: dErr } = await supabase
    .from("plant_media")
    .delete()
    .eq("id", mediaId);
  if (dErr) throw dErr;
}

export function getPublicUrl(storagePath: string): string {
  const { data } = supabase.storage.from(BUCKET).getPublicUrl(storagePath);
  return data.publicUrl;
}


