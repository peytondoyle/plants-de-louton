import { supabase } from "./supabaseClient";
import type { Plant } from "../types/types";

export async function listPlants(): Promise<Plant[]> {
  const { data, error } = await supabase
    .from("plants")
    .select("*")
    .order("name", { ascending: true });
  if (error) throw error;
  return (data ?? []) as Plant[];
}

export async function createPlant(name: string): Promise<Plant> {
  const { data, error } = await supabase
    .from("plants")
    .insert({ name })
    .select("*")
    .single();
  if (error) throw error;
  return data as Plant;
}



