import { supabase } from "./supabaseClient";
import type { BedLatest } from "../types/types";

export async function listBedsBySection(section: string): Promise<BedLatest[]> {
  const { data, error } = await supabase
    .from("beds_latest")
    .select("*")
    .eq("section", section)
    .order("created_at", { ascending: true });

  if (error) throw error;
  return (data ?? []) as BedLatest[];
}