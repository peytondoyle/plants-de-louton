import { supabase } from "./supabaseClient";
import type { CareEvent } from "../types/types";

export async function getCareEvent(id: string): Promise<CareEvent | null> {
  const { data, error } = await supabase
    .from("care_events")
    .select("*")
    .eq("id", id)
    .single();
  if (error) {
    if (error.code === 'PGRST116') return null;
    throw error;
  }
  return data as CareEvent;
}

export async function listCareEventsByPlantInstance(plantInstanceId: string): Promise<CareEvent[]> {
  const { data, error } = await supabase
    .from("care_events")
    .select("*")
    .eq("plant_instance_id", plantInstanceId)
    .order("event_date", { ascending: false });
  if (error) throw error;
  return (data ?? []) as CareEvent[];
}

export async function createCareEvent(event: Omit<CareEvent, 'id' | 'created_at' | 'updated_at'>): Promise<CareEvent> {
  const { data, error } = await supabase
    .from("care_events")
    .insert(event)
    .select("*")
    .single();
  if (error) throw error;
  return data as CareEvent;
}

export async function updateCareEvent(id: string, updates: Partial<CareEvent>): Promise<CareEvent> {
  const { data, error } = await supabase
    .from("care_events")
    .update(updates)
    .eq("id", id)
    .select("*")
    .single();
  if (error) throw error;
  return data as CareEvent;
}

export async function deleteCareEvent(id: string): Promise<void> {
  const { error } = await supabase
    .from("care_events")
    .delete()
    .eq("id", id);
  if (error) throw error;
}

export async function getRecentCareEvents(limit: number = 10): Promise<CareEvent[]> {
  const { data, error } = await supabase
    .from("care_events")
    .select(`
      *,
      plant_instances!inner(
        id,
        plant_details:plant_details_id(name),
        pins!inner(name)
      )
    `)
    .order("event_date", { ascending: false })
    .limit(limit);
  if (error) throw error;
  return (data ?? []) as CareEvent[];
}



