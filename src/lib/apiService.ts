// Enhanced API service layer with rate limiting, error handling, and request/response interceptors

import { cachedApiCall, caches } from './cache';

// API configuration
interface APIConfig {
  baseURL: string;
  timeout: number;
  retries: number;
  rateLimit: {
    requests: number;
    window: number; // in milliseconds
  };
}

// Request/Response interceptors
interface RequestInterceptor {
  (config: RequestConfig): RequestConfig | Promise<RequestConfig>;
}

interface ResponseInterceptor {
  (response: Response, config: RequestConfig): Response | Promise<Response>;
}

interface ErrorInterceptor {
  (error: Error, config: RequestConfig): Error | Promise<Error>;
}

// Request configuration
interface RequestConfig {
  url: string;
  method: string;
  headers?: Record<string, string>;
  body?: any;
  timeout?: number;
  retries?: number;
  cache?: boolean;
  cacheTTL?: number;
}

// Rate limiter class
class RateLimiter {
  private requests: Array<number> = [];
  private readonly maxRequests: number;
  private readonly windowMs: number;

  constructor(maxRequests: number, windowMs: number) {
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
  }

  async waitForSlot(): Promise<void> {
    const now = Date.now();
    
    // Remove expired requests
    this.requests = this.requests.filter(time => now - time < this.windowMs);
    
    // If we're at the limit, wait
    if (this.requests.length >= this.maxRequests) {
      const oldestRequest = this.requests[0];
      const waitTime = this.windowMs - (now - oldestRequest);
      await new Promise(resolve => setTimeout(resolve, waitTime));
      return this.waitForSlot(); // Recursive call to check again
    }
    
    // Add current request
    this.requests.push(now);
  }

  getRemainingRequests(): number {
    const now = Date.now();
    this.requests = this.requests.filter(time => now - time < this.windowMs);
    return Math.max(0, this.maxRequests - this.requests.length);
  }
}

// API Service class
export class APIService {
  private config: APIConfig;
  private rateLimiters: Map<string, RateLimiter> = new Map();
  private requestInterceptors: RequestInterceptor[] = [];
  private responseInterceptors: ResponseInterceptor[] = [];
  private errorInterceptors: ErrorInterceptor[] = [];

  constructor(config: Partial<APIConfig> = {}) {
    this.config = {
      baseURL: '',
      timeout: 30000, // 30 seconds
      retries: 3,
      rateLimit: {
        requests: 100,
        window: 60000, // 1 minute
      },
      ...config,
    };
  }

  // Add interceptors
  addRequestInterceptor(interceptor: RequestInterceptor): void {
    this.requestInterceptors.push(interceptor);
  }

  addResponseInterceptor(interceptor: ResponseInterceptor): void {
    this.responseInterceptors.push(interceptor);
  }

  addErrorInterceptor(interceptor: ErrorInterceptor): void {
    this.errorInterceptors.push(interceptor);
  }

  // Get or create rate limiter for a domain
  private getRateLimiter(domain: string): RateLimiter {
    if (!this.rateLimiters.has(domain)) {
      this.rateLimiters.set(domain, new RateLimiter(
        this.config.rateLimit.requests,
        this.config.rateLimit.window
      ));
    }
    return this.rateLimiters.get(domain)!;
  }

  // Apply request interceptors
  private async applyRequestInterceptors(config: RequestConfig): Promise<RequestConfig> {
    let modifiedConfig = { ...config };
    
    for (const interceptor of this.requestInterceptors) {
      modifiedConfig = await interceptor(modifiedConfig);
    }
    
    return modifiedConfig;
  }

  // Apply response interceptors
  private async applyResponseInterceptors(response: Response, config: RequestConfig): Promise<Response> {
    let modifiedResponse = response;
    
    for (const interceptor of this.responseInterceptors) {
      modifiedResponse = await interceptor(modifiedResponse, config);
    }
    
    return modifiedResponse;
  }

  // Apply error interceptors
  private async applyErrorInterceptors(error: Error, config: RequestConfig): Promise<Error> {
    let modifiedError = error;
    
    for (const interceptor of this.errorInterceptors) {
      modifiedError = await interceptor(modifiedError, config);
    }
    
    return modifiedError;
  }

  // Enhanced fetch with retry logic
  private async fetchWithRetry(config: RequestConfig): Promise<Response> {
    const maxRetries = config.retries || this.config.retries;
    let lastError: Error;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Apply rate limiting
        const domain = new URL(config.url).hostname;
        const rateLimiter = this.getRateLimiter(domain);
        await rateLimiter.waitForSlot();

        // Create fetch options
        const fetchOptions: RequestInit = {
          method: config.method,
          headers: {
            'Content-Type': 'application/json',
            ...config.headers,
          },
        };

        if (config.body) {
          fetchOptions.body = typeof config.body === 'string' 
            ? config.body 
            : JSON.stringify(config.body);
        }

        // Create abort controller for timeout
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), config.timeout || this.config.timeout);
        fetchOptions.signal = controller.signal;

        // Make request
        const response = await fetch(config.url, fetchOptions);
        clearTimeout(timeoutId);

        // Check if response is ok
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        return response;
      } catch (error) {
        lastError = error as Error;
        
        // Don't retry on certain errors
        if (error instanceof TypeError && error.message.includes('aborted')) {
          throw new Error(`Request timeout after ${config.timeout || this.config.timeout}ms`);
        }
        
        if (attempt === maxRetries) {
          break;
        }
        
        // Exponential backoff
        const delay = Math.min(1000 * Math.pow(2, attempt - 1), 10000);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
    
    throw lastError!;
  }

  // Main request method
  async request<T>(config: RequestConfig): Promise<T> {
    try {
      // Apply request interceptors
      const modifiedConfig = await this.applyRequestInterceptors(config);
      
      // Check cache first if enabled
      if (modifiedConfig.cache) {
        const cacheKey = `${modifiedConfig.method}:${modifiedConfig.url}:${JSON.stringify(modifiedConfig.body || '')}`;
        return cachedApiCall(cacheKey, async () => {
          const response = await this.fetchWithRetry(modifiedConfig);
          const processedResponse = await this.applyResponseInterceptors(response, modifiedConfig);
          return processedResponse.json();
        }, modifiedConfig.cacheTTL);
      }
      
      // Make request
      const response = await this.fetchWithRetry(modifiedConfig);
      const processedResponse = await this.applyResponseInterceptors(response, modifiedConfig);
      return processedResponse.json();
    } catch (error) {
      const processedError = await this.applyErrorInterceptors(error as Error, config);
      throw processedError;
    }
  }

  // Convenience methods
  async get<T>(url: string, config: Partial<RequestConfig> = {}): Promise<T> {
    return this.request<T>({
      url: this.config.baseURL + url,
      method: 'GET',
      ...config,
    });
  }

  async post<T>(url: string, data?: any, config: Partial<RequestConfig> = {}): Promise<T> {
    return this.request<T>({
      url: this.config.baseURL + url,
      method: 'POST',
      body: data,
      ...config,
    });
  }

  async put<T>(url: string, data?: any, config: Partial<RequestConfig> = {}): Promise<T> {
    return this.request<T>({
      url: this.config.baseURL + url,
      method: 'PUT',
      body: data,
      ...config,
    });
  }

  async delete<T>(url: string, config: Partial<RequestConfig> = {}): Promise<T> {
    return this.request<T>({
      url: this.config.baseURL + url,
      method: 'DELETE',
      ...config,
    });
  }

  // Get rate limiter status
  getRateLimitStatus(domain: string): { remaining: number; resetTime: number } {
    const rateLimiter = this.rateLimiters.get(domain);
    if (!rateLimiter) {
      return { remaining: this.config.rateLimit.requests, resetTime: Date.now() };
    }
    
    const remaining = rateLimiter.getRemainingRequests();
    const resetTime = Date.now() + this.config.rateLimit.window;
    
    return { remaining, resetTime };
  }

  // Clear all rate limiters
  clearRateLimiters(): void {
    this.rateLimiters.clear();
  }
}

// Default API service instance
export const apiService = new APIService();

// Add default interceptors
apiService.addRequestInterceptor((config) => {
  // Add user agent
  config.headers = {
    ...config.headers,
    'User-Agent': 'Plants-de-Louton/1.0',
  };
  return config;
});

apiService.addResponseInterceptor(async (response, config) => {
  // Log slow responses
  if (response.headers.get('x-response-time')) {
    const responseTime = parseInt(response.headers.get('x-response-time') || '0');
    if (responseTime > 5000) {
      console.warn(`Slow API response: ${config.url} took ${responseTime}ms`);
    }
  }
  return response;
});

apiService.addErrorInterceptor(async (error, config) => {
  // Log errors with context
  console.error(`API Error for ${config.method} ${config.url}:`, error.message);
  return error;
});

// Plant API service (Trefle API)
export class PlantAPIService {
  private apiKey: string;
  private baseURL = 'https://trefle.io/api/v1';

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async searchPlants(query: string, limit: number = 10): Promise<any[]> {
    try {
      const response = await apiService.get<any>(`${this.baseURL}/plants/search`, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
        },
        params: {
          q: query,
          limit,
        },
        cache: true,
        cacheTTL: 30 * 60 * 1000, // 30 minutes
      });

      return response.data || [];
    } catch (error) {
      console.error('Plant API search failed:', error);
      throw new Error('Failed to search plants');
    }
  }

  async getPlantDetails(plantId: string): Promise<any> {
    try {
      const response = await apiService.get<any>(`${this.baseURL}/plants/${plantId}`, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
        },
        cache: true,
        cacheTTL: 60 * 60 * 1000, // 1 hour
      });

      return response.data;
    } catch (error) {
      console.error('Plant API details failed:', error);
      throw new Error('Failed to get plant details');
    }
  }
}

// Weather API service (example)
export class WeatherAPIService {
  private apiKey: string;
  private baseURL = 'https://api.openweathermap.org/data/2.5';

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async getCurrentWeather(lat: number, lon: number): Promise<any> {
    try {
      const response = await apiService.get<any>(`${this.baseURL}/weather`, {
        params: {
          lat,
          lon,
          appid: this.apiKey,
          units: 'metric',
        },
        cache: true,
        cacheTTL: 10 * 60 * 1000, // 10 minutes
      });

      return response;
    } catch (error) {
      console.error('Weather API failed:', error);
      throw new Error('Failed to get weather data');
    }
  }
}

// Export convenience functions
export const api = {
  get: <T>(url: string, config?: Partial<RequestConfig>) => apiService.get<T>(url, config),
  post: <T>(url: string, data?: any, config?: Partial<RequestConfig>) => apiService.post<T>(url, data, config),
  put: <T>(url: string, data?: any, config?: Partial<RequestConfig>) => apiService.put<T>(url, data, config),
  delete: <T>(url: string, config?: Partial<RequestConfig>) => apiService.delete<T>(url, config),
  request: <T>(config: RequestConfig) => apiService.request<T>(config),
};
