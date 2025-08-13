// Comprehensive caching system for database queries and API responses

interface CacheEntry<T> {
  data: T;
  timestamp: number;
  ttl: number;
}

interface CacheOptions {
  ttl?: number; // Time to live in milliseconds
  maxSize?: number; // Maximum number of entries
  namespace?: string; // Cache namespace for organization
}

class Cache {
  private storage = new Map<string, CacheEntry<any>>();
  private readonly defaultTTL = 5 * 60 * 1000; // 5 minutes
  private readonly defaultMaxSize = 1000;
  private readonly namespace: string;

  constructor(options: CacheOptions = {}) {
    this.namespace = options.namespace || 'default';
    this.defaultTTL = options.ttl || this.defaultTTL;
    this.defaultMaxSize = options.maxSize || this.defaultMaxSize;
    
    // Clean up expired entries periodically
    setInterval(() => this.cleanup(), 60000); // Every minute
  }

  private generateKey(key: string): string {
    return `${this.namespace}:${key}`;
  }

  private isExpired(entry: CacheEntry<any>): boolean {
    return Date.now() - entry.timestamp > entry.ttl;
  }

  private cleanup(): void {
    const now = Date.now();
    for (const [key, entry] of this.storage.entries()) {
      if (now - entry.timestamp > entry.ttl) {
        this.storage.delete(key);
      }
    }
  }

  set<T>(key: string, data: T, ttl?: number): void {
    const fullKey = this.generateKey(key);
    const entry: CacheEntry<T> = {
      data,
      timestamp: Date.now(),
      ttl: ttl || this.defaultTTL
    };

    // Implement LRU eviction if cache is full
    if (this.storage.size >= this.defaultMaxSize) {
      const oldestKey = this.storage.keys().next().value;
      this.storage.delete(oldestKey);
    }

    this.storage.set(fullKey, entry);
  }

  get<T>(key: string): T | null {
    const fullKey = this.generateKey(key);
    const entry = this.storage.get(fullKey);

    if (!entry) {
      return null;
    }

    if (this.isExpired(entry)) {
      this.storage.delete(fullKey);
      return null;
    }

    return entry.data as T;
  }

  has(key: string): boolean {
    const fullKey = this.generateKey(key);
    const entry = this.storage.get(fullKey);
    
    if (!entry) {
      return false;
    }

    if (this.isExpired(entry)) {
      this.storage.delete(fullKey);
      return false;
    }

    return true;
  }

  delete(key: string): boolean {
    const fullKey = this.generateKey(key);
    return this.storage.delete(fullKey);
  }

  clear(): void {
    this.storage.clear();
  }

  size(): number {
    return this.storage.size;
  }

  keys(): string[] {
    return Array.from(this.storage.keys()).map(key => key.replace(`${this.namespace}:`, ''));
  }

  // Get cache statistics
  getStats(): { size: number; hitRate: number; namespace: string } {
    return {
      size: this.storage.size,
      hitRate: 0, // Would need to track hits/misses for this
      namespace: this.namespace
    };
  }
}

// Cache instances for different purposes
export const caches = {
  database: new Cache({ namespace: 'db', ttl: 5 * 60 * 1000 }), // 5 minutes
  api: new Cache({ namespace: 'api', ttl: 10 * 60 * 1000 }), // 10 minutes
  search: new Cache({ namespace: 'search', ttl: 30 * 60 * 1000 }), // 30 minutes
  images: new Cache({ namespace: 'images', ttl: 60 * 60 * 1000 }), // 1 hour
};

// Cache decorator for functions
export function cached<T extends (...args: any[]) => Promise<any>>(
  cacheKey: string | ((...args: Parameters<T>) => string),
  options: CacheOptions = {}
): (fn: T) => T {
  const cache = new Cache(options);
  
  return (fn: T): T => {
    return (async (...args: Parameters<T>): Promise<ReturnType<T>> => {
      const key = typeof cacheKey === 'function' ? cacheKey(...args) : cacheKey;
      
      // Try to get from cache first
      const cached = cache.get<ReturnType<T>>(key);
      if (cached !== null) {
        return cached;
      }
      
      // Execute function and cache result
      const result = await fn(...args);
      cache.set(key, result);
      
      return result;
    }) as T;
  };
}

// Database query caching
export async function cachedQuery<T>(
  key: string,
  queryFn: () => Promise<T>,
  ttl?: number
): Promise<T> {
  // Try cache first
  const cached = caches.database.get<T>(key);
  if (cached !== null) {
    return cached;
  }

  // Execute query
  const result = await queryFn();
  
  // Cache result
  caches.database.set(key, result, ttl);
  
  return result;
}

// API response caching
export async function cachedApiCall<T>(
  key: string,
  apiCall: () => Promise<T>,
  ttl?: number
): Promise<T> {
  // Try cache first
  const cached = caches.api.get<T>(key);
  if (cached !== null) {
    return cached;
  }

  // Make API call
  const result = await apiCall();
  
  // Cache result
  caches.api.set(key, result, ttl);
  
  return result;
}

// Cache invalidation utilities
export const cacheInvalidation = {
  // Invalidate all database caches
  invalidateDatabase(): void {
    caches.database.clear();
  },

  // Invalidate specific database cache
  invalidateDatabaseKey(key: string): void {
    caches.database.delete(key);
  },

  // Invalidate all API caches
  invalidateApi(): void {
    caches.api.clear();
  },

  // Invalidate search caches
  invalidateSearch(): void {
    caches.search.clear();
  },

  // Invalidate image caches
  invalidateImages(): void {
    caches.images.clear();
  },

  // Invalidate all caches
  invalidateAll(): void {
    Object.values(caches).forEach(cache => cache.clear());
  },

  // Invalidate caches by pattern
  invalidateByPattern(pattern: string): void {
    Object.values(caches).forEach(cache => {
      cache.keys().forEach(key => {
        if (key.includes(pattern)) {
          cache.delete(key);
        }
      });
    });
  }
};

// Cache statistics and monitoring
export const cacheStats = {
  getAllStats(): Record<string, { size: number; hitRate: number; namespace: string }> {
    const stats: Record<string, { size: number; hitRate: number; namespace: string }> = {};
    
    Object.entries(caches).forEach(([name, cache]) => {
      stats[name] = cache.getStats();
    });
    
    return stats;
  },

  logStats(): void {
    const stats = this.getAllStats();
    console.log('Cache Statistics:', stats);
  },

  // Monitor cache performance
  startMonitoring(intervalMs: number = 60000): () => void {
    const interval = setInterval(() => {
      this.logStats();
    }, intervalMs);

    return () => clearInterval(interval);
  }
};

// Export default cache instance
export default caches.database;

