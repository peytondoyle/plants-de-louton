import { supabase } from './supabaseClient';
import type { PlantPin } from '../types/types';

export async function getPinsBySection(sectionSlug: string): Promise<PlantPin[]> {
  const { data, error } = await supabase
    .from('plant_pins')
    .select('*')
    .eq('section', sectionSlug);

  if (error) {
    console.error('Error fetching pins:', error);
    return [];
  }

  return data as PlantPin[];
}