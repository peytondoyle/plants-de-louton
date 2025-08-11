import { supabase } from "./supabaseClient";
import { v4 as uuidv4 } from "uuid";

const BUCKET = "plant-images"; // reuse existing bucket

export type PinMediaRow = {
  id: string;
  pin_id: string;
  image_id?: string | null;
  storage_path: string;
  caption?: string | null;
  captured_at?: string | null;
  created_at: string;
};

export async function getPinMedia(pinId: string): Promise<(PinMediaRow & { url: string })[]> {
  const { data, error } = await supabase
    .from("pin_media")
    .select("*")
    .eq("pin_id", pinId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  const list = (data ?? []) as PinMediaRow[];
  return list.map((m) => {
    const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(m.storage_path);
    return { ...m, url: pub.publicUrl };
  });
}

export async function uploadPinMedia(
  pinId: string,
  file: File,
  link?: { imageId?: string; caption?: string; capturedAt?: string }
): Promise<void> {
  const ext = (file.name.split(".").pop() || "jpg").toLowerCase();
  const path = `pin/${pinId}/${uuidv4()}.${ext}`;
  const { error: upErr } = await supabase.storage
    .from(BUCKET)
    .upload(path, file, { cacheControl: "3600", upsert: false, contentType: file.type || "image/jpeg" });
  if (upErr) throw upErr;

  const { error } = await supabase
    .from("pin_media")
    .insert({
      pin_id: pinId,
      image_id: link?.imageId ?? null,
      storage_path: path,
      caption: link?.caption ?? null,
      captured_at: link?.capturedAt ?? null,
    });
  if (error) throw error;
}

export async function deletePinMedia(mediaId: string): Promise<void> {
  const { data, error } = await supabase
    .from("pin_media")
    .select("id, storage_path")
    .eq("id", mediaId)
    .maybeSingle();
  if (error) throw error;
  const path = (data as { storage_path: string } | null)?.storage_path;
  if (!path) return;
  const { error: sErr } = await supabase.storage.from(BUCKET).remove([path]);
  if (sErr) throw sErr;
  const { error: dErr } = await supabase.from("pin_media").delete().eq("id", mediaId);
  if (dErr) throw dErr;
}



