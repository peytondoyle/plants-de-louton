import { createClient, SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('Missing Supabase environment variables');
  throw new Error('Missing required Supabase environment variables');
}

// Enhanced Supabase client configuration
export const supabase: SupabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false
  },
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  },
  global: {
    headers: {
      'X-Client-Info': 'plants-de-louton-web'
    }
  }
});

// Error handling utilities
export class DatabaseError extends Error {
  constructor(
    message: string,
    public code?: string,
    public details?: any
  ) {
    super(message);
    this.name = 'DatabaseError';
  }
}

// Retry configuration
const RETRY_CONFIG = {
  maxAttempts: 3,
  baseDelay: 1000, // 1 second
  maxDelay: 5000,  // 5 seconds
};

// Exponential backoff retry function
async function withRetry<T>(
  operation: () => Promise<T>,
  maxAttempts: number = RETRY_CONFIG.maxAttempts
): Promise<T> {
  let lastError: Error;
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error as Error;
      
      if (attempt === maxAttempts) {
        throw new DatabaseError(
          `Operation failed after ${maxAttempts} attempts: ${lastError.message}`,
          'RETRY_EXHAUSTED',
          { originalError: lastError, attempts: attempt }
        );
      }
      
      // Exponential backoff with jitter
      const delay = Math.min(
        RETRY_CONFIG.baseDelay * Math.pow(2, attempt - 1) + Math.random() * 1000,
        RETRY_CONFIG.maxDelay
      );
      
      console.warn(`Database operation failed (attempt ${attempt}/${maxAttempts}), retrying in ${delay}ms:`, lastError.message);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  throw lastError!;
}

// Enhanced query builder with retry logic
export const db = {
  // Generic query with retry
  async query<T>(
    operation: () => Promise<{ data: T | null; error: any }>
  ): Promise<T> {
    const result = await withRetry(operation);
    
    if (result.error) {
      throw new DatabaseError(
        `Database query failed: ${result.error.message}`,
        result.error.code,
        result.error
      );
    }
    
    return result.data as T;
  },

  // Batch operations
  async batch<T>(
    operations: (() => Promise<{ data: T | null; error: any }>)[]
  ): Promise<T[]> {
    const results = await Promise.allSettled(
      operations.map(op => withRetry(op))
    );
    
    const successful: T[] = [];
    const errors: Error[] = [];
    
    results.forEach((result, index) => {
      if (result.status === 'fulfilled') {
        if (result.value.error) {
          errors.push(new DatabaseError(
            `Batch operation ${index} failed: ${result.value.error.message}`,
            result.value.error.code,
            result.value.error
          ));
        } else {
          successful.push(result.value.data as T);
        }
      } else {
        errors.push(result.reason);
      }
    });
    
    if (errors.length > 0) {
      console.error('Batch operation errors:', errors);
      // For now, we'll return successful results and log errors
      // In production, you might want to throw or handle differently
    }
    
    return successful;
  },

  // Connection health check
  async healthCheck(): Promise<boolean> {
    try {
      const { data, error } = await supabase
        .from('pins')
        .select('count')
        .limit(1);
      
      return !error;
    } catch (error) {
      console.error('Database health check failed:', error);
      return false;
    }
  }
};

// Performance monitoring
export const performance = {
  queries: new Map<string, { count: number; totalTime: number; avgTime: number }>(),
  
  startTimer(queryName: string): () => void {
    const start = performance.now();
    return () => {
      const duration = performance.now() - start;
      const stats = this.queries.get(queryName) || { count: 0, totalTime: 0, avgTime: 0 };
      
      stats.count++;
      stats.totalTime += duration;
      stats.avgTime = stats.totalTime / stats.count;
      
      this.queries.set(queryName, stats);
      
      // Log slow queries
      if (duration > 1000) {
        console.warn(`Slow query detected: ${queryName} took ${duration.toFixed(2)}ms`);
      }
    };
  },
  
  getStats(): Record<string, { count: number; avgTime: number }> {
    const stats: Record<string, { count: number; avgTime: number }> = {};
    this.queries.forEach((value, key) => {
      stats[key] = { count: value.count, avgTime: value.avgTime };
    });
    return stats;
  }
};

// Export enhanced client
export { supabase as default };