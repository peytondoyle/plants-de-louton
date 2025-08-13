import { supabase } from "./supabaseClient";
import type { PlantDetails } from "../types/types";

export async function listPlantDetails(): Promise<PlantDetails[]> {
  const { data, error } = await supabase
    .from("plant_details")
    .select("*")
    .order("name", { ascending: true });
  if (error) throw error;
  return (data ?? []) as PlantDetails[];
}

export async function getPlantDetails(id: string): Promise<PlantDetails | null> {
  const { data, error } = await supabase
    .from("plant_details")
    .select("*")
    .eq("id", id)
    .single();
  if (error) {
    if (error.code === 'PGRST116') return null; // No rows returned
    throw error;
  }
  return data as PlantDetails;
}

export async function createPlantDetails(details: Omit<PlantDetails, 'id' | 'created_at' | 'updated_at'>): Promise<PlantDetails> {
  const { data, error } = await supabase
    .from("plant_details")
    .insert(details)
    .select("*")
    .single();
  if (error) throw error;
  return data as PlantDetails;
}

export async function updatePlantDetails(id: string, updates: Partial<PlantDetails>): Promise<PlantDetails> {
  const { data, error } = await supabase
    .from("plant_details")
    .update(updates)
    .eq("id", id)
    .select("*")
    .single();
  if (error) throw error;
  return data as PlantDetails;
}

export async function deletePlantDetails(id: string): Promise<void> {
  const { error } = await supabase
    .from("plant_details")
    .delete()
    .eq("id", id);
  if (error) throw error;
}

export async function searchPlantDetails(query: string): Promise<PlantDetails[]> {
  const { data, error } = await supabase
    .from("plant_details")
    .select("*")
    .or(`name.ilike.%${query}%,scientific_name.ilike.%${query}%`)
    .order("name", { ascending: true });
  if (error) throw error;
  return (data ?? []) as PlantDetails[];
}



