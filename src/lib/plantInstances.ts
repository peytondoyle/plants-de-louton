import { supabase } from "./supabaseClient";
import type { PlantInstance } from "../types/types";

export async function getPlantInstance(id: string): Promise<PlantInstance | null> {
  const { data, error } = await supabase
    .from("plant_instances")
    .select(`
      *,
      plant_details:plant_details_id(*)
    `)
    .eq("id", id)
    .single();
  if (error) {
    if (error.code === 'PGRST116') return null;
    throw error;
  }
  return data as PlantInstance;
}

export async function getPlantInstanceByPinId(pinId: string): Promise<PlantInstance | null> {
  const { data, error } = await supabase
    .from("plant_instances")
    .select(`
      *,
      plant_details:plant_details_id(*)
    `)
    .eq("pin_id", pinId)
    .single();
  if (error) {
    if (error.code === 'PGRST116') return null;
    throw error;
  }
  return data as PlantInstance;
}

export async function createPlantInstance(instance: Omit<PlantInstance, 'id' | 'created_at' | 'updated_at'>): Promise<PlantInstance> {
  const { data, error } = await supabase
    .from("plant_instances")
    .insert(instance)
    .select(`
      *,
      plant_details:plant_details_id(*)
    `)
    .single();
  if (error) throw error;
  return data as PlantInstance;
}

export async function updatePlantInstance(id: string, updates: Partial<PlantInstance>): Promise<PlantInstance> {
  const { data, error } = await supabase
    .from("plant_instances")
    .update(updates)
    .eq("id", id)
    .select(`
      *,
      plant_details:plant_details_id(*)
    `)
    .single();
  if (error) throw error;
  return data as PlantInstance;
}

export async function deletePlantInstance(id: string): Promise<void> {
  const { error } = await supabase
    .from("plant_instances")
    .delete()
    .eq("id", id);
  if (error) throw error;
}

export async function listPlantInstancesByBed(bedId: string): Promise<PlantInstance[]> {
  const { data, error } = await supabase
    .from("plant_instances")
    .select(`
      *,
      plant_details:plant_details_id(*)
    `)
    .eq("bed_id", bedId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return (data ?? []) as PlantInstance[];
}



