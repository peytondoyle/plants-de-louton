// Comprehensive backend utilities - unified interface for all backend operations

import { databaseService, DatabaseService } from './database';
import { apiService, APIService, PlantAPIService } from './apiService';
import { caches, cacheInvalidation, cacheStats } from './cache';
import { migrationManager, MigrationManager } from './migrations';
import { performance } from './supabaseClient';

// Backend service class - unified interface
export class BackendService {
  private static instance: BackendService;
  
  // Service instances
  public readonly database: DatabaseService;
  public readonly api: APIService;
  public readonly migrations: MigrationManager;
  
  // API services
  public readonly plantAPI: PlantAPIService | null;
  
  private constructor() {
    this.database = databaseService;
    this.api = apiService;
    this.migrations = migrationManager;
    
    // Initialize API services
    const TREFFLE_API_TOKEN = import.meta.env.VITE_TREFFLE_API_TOKEN;
    this.plantAPI = TREFFLE_API_TOKEN ? new PlantAPIService(TREFFLE_API_TOKEN) : null;
  }
  
  static getInstance(): BackendService {
    if (!BackendService.instance) {
      BackendService.instance = new BackendService();
    }
    return BackendService.instance;
  }

  // Health check for all services
  async healthCheck(): Promise<{
    database: { healthy: boolean; latency: number; error?: string };
    api: { healthy: boolean; rateLimitStatus: Record<string, any> };
    cache: { healthy: boolean; stats: Record<string, any> };
    overall: boolean;
  }> {
    const results = await Promise.allSettled([
      this.database.healthCheck(),
      this.getAPIRateLimitStatus(),
      this.getCacheStats()
    ]);

    const [dbResult, apiResult, cacheResult] = results.map(result => 
      result.status === 'fulfilled' ? result.value : null
    );

    const overall = results.every(result => result.status === 'fulfilled');

    return {
      database: dbResult || { healthy: false, latency: 0, error: 'Health check failed' },
      api: apiResult || { healthy: false, rateLimitStatus: {} },
      cache: cacheResult || { healthy: false, stats: {} },
      overall
    };
  }

  // API rate limit status
  async getAPIRateLimitStatus(): Promise<{ healthy: boolean; rateLimitStatus: Record<string, any> }> {
    const domains = ['trefle.io', 'api.openweathermap.org'];
    const rateLimitStatus: Record<string, any> = {};

    for (const domain of domains) {
      rateLimitStatus[domain] = this.api.getRateLimitStatus(domain);
    }

    return {
      healthy: true,
      rateLimitStatus
    };
  }

  // Cache statistics
  async getCacheStats(): Promise<{ healthy: boolean; stats: Record<string, any> }> {
    const stats = cacheStats.getAllStats();
    return {
      healthy: Object.values(stats).every(stat => stat.size >= 0),
      stats
    };
  }

  // Performance monitoring
  getPerformanceStats() {
    return performance.getStats();
  }

  // Cache management
  clearAllCaches(): void {
    cacheInvalidation.invalidateAll();
  }

  clearDatabaseCache(): void {
    cacheInvalidation.invalidateDatabase();
  }

  clearAPICache(): void {
    cacheInvalidation.invalidateApi();
  }

  // Database maintenance
  async cleanupDatabase(): Promise<{ deleted: number; errors: string[] }> {
    return this.database.cleanupOrphanedRecords();
  }

  // Migration management
  async runMigrations(): Promise<{ applied: number; errors: string[] }> {
    return this.migrations.migrate();
  }

  async getMigrationStatus() {
    return this.migrations.status();
  }

  async rollbackMigrations(steps: number = 1): Promise<{ rolledBack: number; errors: string[] }> {
    return this.migrations.rollback(steps);
  }

  // Enhanced search with multiple sources
  async enhancedPlantSearch(query: string): Promise<any[]> {
    const results: any[] = [];
    
    // Try database search first
    try {
      const dbResults = await this.database.searchPins(query);
      results.push(...dbResults.map(result => ({ ...result, source: 'database' })));
    } catch (error) {
      console.error('Database search failed:', error);
    }

    // Try API search if available
    if (this.plantAPI) {
      try {
        const apiResults = await this.plantAPI.searchPlants(query, 5);
        results.push(...apiResults.map(result => ({ ...result, source: 'api' })));
      } catch (error) {
        console.error('API search failed:', error);
      }
    }

    // Remove duplicates and sort by relevance
    const uniqueResults = this.deduplicateResults(results);
    return uniqueResults.slice(0, 10); // Limit to 10 results
  }

  // Deduplicate search results
  private deduplicateResults(results: any[]): any[] {
    const seen = new Set<string>();
    return results.filter(result => {
      const key = result.scientific_name || result.name;
      if (seen.has(key)) {
        return false;
      }
      seen.add(key);
      return true;
    });
  }

  // Batch operations
  async batchCreatePins(pins: any[]): Promise<any[]> {
    return this.database.batchCreatePins(pins);
  }

  async batchUpdatePins(updates: { id: string; updates: any }[]): Promise<any[]> {
    return this.database.batchUpdatePins(updates);
  }

  // Statistics and analytics
  async getSystemStats(): Promise<{
    database: any;
    cache: any;
    performance: any;
    api: any;
  }> {
    const [dbStats, cacheStats, perfStats, apiStats] = await Promise.all([
      this.database.getPinStats(),
      this.getCacheStats(),
      Promise.resolve(this.getPerformanceStats()),
      this.getAPIRateLimitStatus()
    ]);

    return {
      database: dbStats,
      cache: cacheStats,
      performance: perfStats,
      api: apiStats
    };
  }

  // Error handling and logging
  async logError(error: Error, context: string): Promise<void> {
    console.error(`[${context}] Error:`, error);
    
    // In a production environment, you might want to send this to a logging service
    // await this.api.post('/logs/error', {
    //   message: error.message,
    //   stack: error.stack,
    //   context,
    //   timestamp: new Date().toISOString()
    // });
  }

  // Configuration management
  getConfig(): {
    hasPlantAPI: boolean;
    hasWeatherAPI: boolean;
    cacheEnabled: boolean;
    retryEnabled: boolean;
  } {
    return {
      hasPlantAPI: !!this.plantAPI,
      hasWeatherAPI: false, // Add when weather API is implemented
      cacheEnabled: true,
      retryEnabled: true
    };
  }
}

// Export singleton instance
export const backend = BackendService.getInstance();

// Convenience functions for common operations
export const backendUtils = {
  // Health checks
  healthCheck: () => backend.healthCheck(),
  
  // Database operations
  getBeds: () => backend.database.getBeds(),
  getBed: (id: string) => backend.database.getBed(id),
  getPinsBySection: (sectionId: string) => backend.database.getPinsBySection(sectionId),
  getPin: (id: string) => backend.database.getPin(id),
  createPin: (pin: any) => backend.database.createPin(pin),
  updatePin: (id: string, updates: any) => backend.database.updatePin(id, updates),
  deletePin: (id: string) => backend.database.deletePin(id),
  
  // Search operations
  searchPlants: (query: string) => backend.enhancedPlantSearch(query),
  
  // Cache operations
  clearCache: () => backend.clearAllCaches(),
  getCacheStats: () => backend.getCacheStats(),
  
  // Performance monitoring
  getPerformanceStats: () => backend.getPerformanceStats(),
  
  // System operations
  getSystemStats: () => backend.getSystemStats(),
  cleanupDatabase: () => backend.cleanupDatabase(),
  
  // Migration operations
  runMigrations: () => backend.runMigrations(),
  getMigrationStatus: () => backend.getMigrationStatus(),
  rollbackMigrations: (steps: number) => backend.rollbackMigrations(steps),
  
  // Configuration
  getConfig: () => backend.getConfig(),
  
  // Error logging
  logError: (error: Error, context: string) => backend.logError(error, context)
};

// Development utilities (only available in development)
if (import.meta.env.DEV) {
  (window as any).backend = {
    ...backendUtils,
    // Additional development-only utilities
    debug: {
      clearAllCaches: () => backend.clearAllCaches(),
      getPerformanceStats: () => backend.getPerformanceStats(),
      getSystemStats: () => backend.getSystemStats(),
      healthCheck: () => backend.healthCheck(),
      runMigrations: () => backend.runMigrations(),
      cleanupDatabase: () => backend.cleanupDatabase()
    }
  };
}

// Export for use in components
export default backend;
