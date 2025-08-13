// Enhanced database service layer with performance optimizations and error handling

import { supabase, db, DatabaseError, performance } from './supabaseClient';
import { caches, cachedQuery, cacheInvalidation } from './cache';
import type { Pin, Bed, PlantDetails, PlantInstance, CareEvent, PlantMedia } from '../types/types';

// Database service class for centralized database operations
export class DatabaseService {
  private static instance: DatabaseService;
  
  private constructor() {}
  
  static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService();
    }
    return DatabaseService.instance;
  }

  // Health check and connection management
  async healthCheck(): Promise<{ healthy: boolean; latency: number; error?: string }> {
    const timer = performance.startTimer('health_check');
    try {
      const start = Date.now();
      const healthy = await db.healthCheck();
      const latency = Date.now() - start;
      timer();
      
      return { healthy, latency };
    } catch (error) {
      timer();
      return { 
        healthy: false, 
        latency: 0, 
        error: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  // Enhanced bed operations with caching
  async getBeds(): Promise<Bed[]> {
    return cachedQuery('beds:all', async () => {
      const timer = performance.startTimer('get_beds');
      try {
        const { data, error } = await supabase
          .from('beds')
          .select('*')
          .order('name');
        
        if (error) throw new DatabaseError('Failed to fetch beds', error.code, error);
        timer();
        return data || [];
      } catch (error) {
        timer();
        throw error;
      }
    });
  }

  async getBed(id: string): Promise<Bed | null> {
    return cachedQuery(`bed:${id}`, async () => {
      const timer = performance.startTimer('get_bed');
      try {
        const { data, error } = await supabase
          .from('beds')
          .select('*')
          .eq('id', id)
          .single();
        
        if (error && error.code !== 'PGRST116') {
          throw new DatabaseError('Failed to fetch bed', error.code, error);
        }
        timer();
        return data;
      } catch (error) {
        timer();
        throw error;
      }
    });
  }

  // Enhanced pin operations with batch capabilities
  async getPinsBySection(sectionId: string): Promise<Pin[]> {
    return cachedQuery(`pins:section:${sectionId}`, async () => {
      const timer = performance.startTimer('get_pins_by_section');
      try {
        const { data, error } = await supabase
          .from('pins')
          .select(`
            *,
            plant_instance:plant_instances(*),
            plant_details:plant_instances(plant_details(*))
          `)
          .eq('section_id', sectionId)
          .order('created_at', { ascending: false });
        
        if (error) throw new DatabaseError('Failed to fetch pins', error.code, error);
        timer();
        return data || [];
      } catch (error) {
        timer();
        throw error;
      }
    });
  }

  async getPin(id: string): Promise<Pin | null> {
    return cachedQuery(`pin:${id}`, async () => {
      const timer = performance.startTimer('get_pin');
      try {
        const { data, error } = await supabase
          .from('pins')
          .select(`
            *,
            plant_instance:plant_instances(*),
            plant_details:plant_instances(plant_details(*))
          `)
          .eq('id', id)
          .single();
        
        if (error && error.code !== 'PGRST116') {
          throw new DatabaseError('Failed to fetch pin', error.code, error);
        }
        timer();
        return data;
      } catch (error) {
        timer();
        throw error;
      }
    });
  }

  async createPin(pin: Omit<Pin, 'id' | 'created_at' | 'updated_at'>): Promise<Pin> {
    const timer = performance.startTimer('create_pin');
    try {
      const { data, error } = await supabase
        .from('pins')
        .insert(pin)
        .select('*')
        .single();
      
      if (error) throw new DatabaseError('Failed to create pin', error.code, error);
      
      // Invalidate related caches
      cacheInvalidation.invalidateByPattern('pins:section');
      cacheInvalidation.invalidateByPattern('beds');
      
      timer();
      return data;
    } catch (error) {
      timer();
      throw error;
    }
  }

  async updatePin(id: string, updates: Partial<Pin>): Promise<Pin> {
    const timer = performance.startTimer('update_pin');
    try {
      const { data, error } = await supabase
        .from('pins')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select('*')
        .single();
      
      if (error) throw new DatabaseError('Failed to update pin', error.code, error);
      
      // Invalidate related caches
      cacheInvalidation.invalidateDatabaseKey(`pin:${id}`);
      cacheInvalidation.invalidateByPattern('pins:section');
      
      timer();
      return data;
    } catch (error) {
      timer();
      throw error;
    }
  }

  async deletePin(id: string): Promise<void> {
    const timer = performance.startTimer('delete_pin');
    try {
      const { error } = await supabase
        .from('pins')
        .delete()
        .eq('id', id);
      
      if (error) throw new DatabaseError('Failed to delete pin', error.code, error);
      
      // Invalidate related caches
      cacheInvalidation.invalidateDatabaseKey(`pin:${id}`);
      cacheInvalidation.invalidateByPattern('pins:section');
      
      timer();
    } catch (error) {
      timer();
      throw error;
    }
  }

  // Batch operations for better performance
  async batchCreatePins(pins: Omit<Pin, 'id' | 'created_at' | 'updated_at'>[]): Promise<Pin[]> {
    const timer = performance.startTimer('batch_create_pins');
    try {
      const operations = pins.map(pin => () => 
        supabase.from('pins').insert(pin).select('*').single()
      );
      
      const results = await db.batch(operations);
      
      // Invalidate related caches
      cacheInvalidation.invalidateByPattern('pins:section');
      cacheInvalidation.invalidateByPattern('beds');
      
      timer();
      return results;
    } catch (error) {
      timer();
      throw error;
    }
  }

  async batchUpdatePins(updates: { id: string; updates: Partial<Pin> }[]): Promise<Pin[]> {
    const timer = performance.startTimer('batch_update_pins');
    try {
      const operations = updates.map(({ id, updates: pinUpdates }) => () =>
        supabase
          .from('pins')
          .update({ ...pinUpdates, updated_at: new Date().toISOString() })
          .eq('id', id)
          .select('*')
          .single()
      );
      
      const results = await db.batch(operations);
      
      // Invalidate related caches
      updates.forEach(({ id }) => cacheInvalidation.invalidateDatabaseKey(`pin:${id}`));
      cacheInvalidation.invalidateByPattern('pins:section');
      
      timer();
      return results;
    } catch (error) {
      timer();
      throw error;
    }
  }

  // Enhanced plant details operations
  async getPlantDetails(id: string): Promise<PlantDetails | null> {
    return cachedQuery(`plant_details:${id}`, async () => {
      const timer = performance.startTimer('get_plant_details');
      try {
        const { data, error } = await supabase
          .from('plant_details')
          .select('*')
          .eq('id', id)
          .single();
        
        if (error && error.code !== 'PGRST116') {
          throw new DatabaseError('Failed to fetch plant details', error.code, error);
        }
        timer();
        return data;
      } catch (error) {
        timer();
        throw error;
      }
    });
  }

  async createPlantDetails(details: Omit<PlantDetails, 'id' | 'created_at' | 'updated_at'>): Promise<PlantDetails> {
    const timer = performance.startTimer('create_plant_details');
    try {
      const { data, error } = await supabase
        .from('plant_details')
        .insert(details)
        .select('*')
        .single();
      
      if (error) throw new DatabaseError('Failed to create plant details', error.code, error);
      
      // Invalidate related caches
      cacheInvalidation.invalidateByPattern('plant_details');
      
      timer();
      return data;
    } catch (error) {
      timer();
      throw error;
    }
  }

  async updatePlantDetails(id: string, updates: Partial<PlantDetails>): Promise<PlantDetails> {
    const timer = performance.startTimer('update_plant_details');
    try {
      const { data, error } = await supabase
        .from('plant_details')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select('*')
        .single();
      
      if (error) throw new DatabaseError('Failed to update plant details', error.code, error);
      
      // Invalidate related caches
      cacheInvalidation.invalidateDatabaseKey(`plant_details:${id}`);
      
      timer();
      return data;
    } catch (error) {
      timer();
      throw error;
    }
  }

  // Enhanced plant instance operations
  async getPlantInstance(id: string): Promise<PlantInstance | null> {
    return cachedQuery(`plant_instance:${id}`, async () => {
      const timer = performance.startTimer('get_plant_instance');
      try {
        const { data, error } = await supabase
          .from('plant_instances')
          .select(`
            *,
            plant_details(*)
          `)
          .eq('id', id)
          .single();
        
        if (error && error.code !== 'PGRST116') {
          throw new DatabaseError('Failed to fetch plant instance', error.code, error);
        }
        timer();
        return data;
      } catch (error) {
        timer();
        throw error;
      }
    });
  }

  async createPlantInstance(instance: Omit<PlantInstance, 'id' | 'created_at' | 'updated_at'>): Promise<PlantInstance> {
    const timer = performance.startTimer('create_plant_instance');
    try {
      const { data, error } = await supabase
        .from('plant_instances')
        .insert(instance)
        .select(`
          *,
          plant_details(*)
        `)
        .single();
      
      if (error) throw new DatabaseError('Failed to create plant instance', error.code, error);
      
      // Invalidate related caches
      cacheInvalidation.invalidateByPattern('plant_instance');
      cacheInvalidation.invalidateByPattern('pins');
      
      timer();
      return data;
    } catch (error) {
      timer();
      throw error;
    }
  }

  // Enhanced care events operations
  async getCareEvents(plantInstanceId: string): Promise<CareEvent[]> {
    return cachedQuery(`care_events:${plantInstanceId}`, async () => {
      const timer = performance.startTimer('get_care_events');
      try {
        const { data, error } = await supabase
          .from('care_events')
          .select('*')
          .eq('plant_instance_id', plantInstanceId)
          .order('event_date', { ascending: false });
        
        if (error) throw new DatabaseError('Failed to fetch care events', error.code, error);
        timer();
        return data || [];
      } catch (error) {
        timer();
        throw error;
      }
    });
  }

  async createCareEvent(event: Omit<CareEvent, 'id' | 'created_at' | 'updated_at'>): Promise<CareEvent> {
    const timer = performance.startTimer('create_care_event');
    try {
      const { data, error } = await supabase
        .from('care_events')
        .insert(event)
        .select('*')
        .single();
      
      if (error) throw new DatabaseError('Failed to create care event', error.code, error);
      
      // Invalidate related caches
      cacheInvalidation.invalidateByPattern(`care_events:${event.plant_instance_id}`);
      
      timer();
      return data;
    } catch (error) {
      timer();
      throw error;
    }
  }

  // Enhanced media operations
  async getPinMedia(pinId: string): Promise<PlantMedia[]> {
    return cachedQuery(`pin_media:${pinId}`, async () => {
      const timer = performance.startTimer('get_pin_media');
      try {
        const { data, error } = await supabase
          .from('plant_media')
          .select('*')
          .eq('pin_id', pinId)
          .order('created_at', { ascending: false });
        
        if (error) throw new DatabaseError('Failed to fetch pin media', error.code, error);
        timer();
        return data || [];
      } catch (error) {
        timer();
        throw error;
      }
    });
  }

  // Search and filtering operations
  async searchPins(query: string, sectionId?: string): Promise<Pin[]> {
    const timer = performance.startTimer('search_pins');
    try {
      let queryBuilder = supabase
        .from('pins')
        .select(`
          *,
          plant_instance:plant_instances(*),
          plant_details:plant_instances(plant_details(*))
        `)
        .or(`name.ilike.%${query}%,notes.ilike.%${query}%`);
      
      if (sectionId) {
        queryBuilder = queryBuilder.eq('section_id', sectionId);
      }
      
      const { data, error } = await queryBuilder.order('created_at', { ascending: false });
      
      if (error) throw new DatabaseError('Failed to search pins', error.code, error);
      timer();
      return data || [];
    } catch (error) {
      timer();
      throw error;
    }
  }

  // Statistics and analytics
  async getPinStats(sectionId?: string): Promise<{
    total: number;
    active: number;
    dormant: number;
    removed: number;
    dead: number;
  }> {
    const timer = performance.startTimer('get_pin_stats');
    try {
      let queryBuilder = supabase
        .from('pins')
        .select('status');
      
      if (sectionId) {
        queryBuilder = queryBuilder.eq('section_id', sectionId);
      }
      
      const { data, error } = await queryBuilder;
      
      if (error) throw new DatabaseError('Failed to fetch pin stats', error.code, error);
      
      const stats = {
        total: data?.length || 0,
        active: data?.filter(pin => pin.status === 'active').length || 0,
        dormant: data?.filter(pin => pin.status === 'dormant').length || 0,
        removed: data?.filter(pin => pin.status === 'removed').length || 0,
        dead: data?.filter(pin => pin.status === 'dead').length || 0,
      };
      
      timer();
      return stats;
    } catch (error) {
      timer();
      throw error;
    }
  }

  // Database maintenance operations
  async cleanupOrphanedRecords(): Promise<{ deleted: number; errors: string[] }> {
    const timer = performance.startTimer('cleanup_orphaned_records');
    try {
      const errors: string[] = [];
      let deleted = 0;

      // Clean up orphaned plant instances
      const { error: instanceError } = await supabase
        .from('plant_instances')
        .delete()
        .is('pin_id', null);
      
      if (instanceError) {
        errors.push(`Failed to cleanup orphaned plant instances: ${instanceError.message}`);
      } else {
        deleted++;
      }

      // Clean up orphaned care events
      const { error: careError } = await supabase
        .from('care_events')
        .delete()
        .is('plant_instance_id', null);
      
      if (careError) {
        errors.push(`Failed to cleanup orphaned care events: ${careError.message}`);
      } else {
        deleted++;
      }

      // Clean up orphaned media
      const { error: mediaError } = await supabase
        .from('plant_media')
        .delete()
        .is('pin_id', null);
      
      if (mediaError) {
        errors.push(`Failed to cleanup orphaned media: ${mediaError.message}`);
      } else {
        deleted++;
      }

      // Invalidate all caches after cleanup
      cacheInvalidation.invalidateAll();
      
      timer();
      return { deleted, errors };
    } catch (error) {
      timer();
      throw error;
    }
  }

  // Export performance statistics
  getPerformanceStats() {
    return performance.getStats();
  }

  // Clear all caches
  clearCaches(): void {
    cacheInvalidation.invalidateAll();
  }
}

// Export singleton instance
export const databaseService = DatabaseService.getInstance();

// Convenience functions for backward compatibility
export const getBeds = () => databaseService.getBeds();
export const getBed = (id: string) => databaseService.getBed(id);
export const getPinsBySection = (sectionId: string) => databaseService.getPinsBySection(sectionId);
export const getPin = (id: string) => databaseService.getPin(id);
export const createPin = (pin: Omit<Pin, 'id' | 'created_at' | 'updated_at'>) => databaseService.createPin(pin);
export const updatePin = (id: string, updates: Partial<Pin>) => databaseService.updatePin(id, updates);
export const deletePin = (id: string) => databaseService.deletePin(id);
