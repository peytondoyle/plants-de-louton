import { describe, it, expect, vi, beforeEach } from 'vitest';
import { searchPlants, type AIPlantSearchResult } from './aiPlantSearch';

// Mock environment variables
vi.mock('import.meta.env', () => ({
  VITE_TREFFLE_API_TOKEN: 'test-token'
}));

// Mock Supabase
vi.mock('./supabaseClient', () => ({
  supabase: {
    from: vi.fn(() => ({
      upsert: vi.fn(() => Promise.resolve({ error: null })),
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          single: vi.fn(() => Promise.resolve({ data: null, error: null }))
        }))
      }))
    }))
  }
}));

// Mock fetch
global.fetch = vi.fn();

describe('AI Plant Search', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.resetAllMocks();
  });

  describe('searchPlants', () => {
    it('returns empty array for empty query', async () => {
      const result = await searchPlants('');
      expect(result).toEqual([]);
    });

    it('returns empty array for whitespace-only query', async () => {
      const result = await searchPlants('   ');
      expect(result).toEqual([]);
    });

    it('handles API errors gracefully', async () => {
      // Mock fetch to throw an error
      vi.mocked(fetch).mockRejectedValueOnce(new Error('API Error'));

      // Should fall back to mock data instead of throwing
      const result = await searchPlants('tomato');
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('Tomato');
    });

    it('handles API response with no data', async () => {
      // Mock fetch to return empty data
      vi.mocked(fetch).mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ data: [] })
      } as Response);

      const result = await searchPlants('nonexistent');
      expect(result).toEqual([]);
    });

    it('transforms API response correctly', async () => {
      const mockApiResponse = {
        data: [
          {
            common_name: 'Tomato',
            scientific_name: 'Solanum lycopersicum',
            common_names: 'Tomato, Love Apple',
            family: 'Solanaceae',
            genus: 'Solanum',
            species: 'lycopersicum',
            growth_habit: 'annual',
            sun_exposure: 'full_sun',
            water_needs: 'moderate',
            mature_height: 60,
            mature_width: 24,
            bloom_time: 'summer',
            bloom_duration: 12,
            flower_color: 'yellow',
            foliage_color: 'green',
            soil_type: 'well_draining',
            soil_ph: 'neutral',
            fertilizer_needs: 'moderate',
            pruning_needs: 'moderate',
            planting_season: 'spring',
            planting_depth: 0.25,
            spacing: 24
          }
        ]
      };

      vi.mocked(fetch).mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(mockApiResponse)
      } as Response);

      const result = await searchPlants('tomato');
      
      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({
        name: 'Tomato',
        scientific_name: 'Solanum lycopersicum',
        common_names: ['Tomato', 'Love Apple'],
        family: 'Solanaceae',
        growth_habit: 'annual',
        sun_exposure: 'full_sun',
        water_needs: 'moderate'
      });
    });

    it('falls back to mock data when API fails', async () => {
      // Mock fetch to fail
      vi.mocked(fetch).mockRejectedValueOnce(new Error('Network error'));

      const result = await searchPlants('calendula');
      
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('Calendula');
      expect(result[0].scientific_name).toBe('Calendula officinalis');
    });

    it('searches mock data correctly', async () => {
      // Mock fetch to fail to trigger mock data fallback
      vi.mocked(fetch).mockRejectedValueOnce(new Error('Network error'));

      const result = await searchPlants('tomato');
      
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('Tomato');
    });

    it('returns multiple results from mock data', async () => {
      // Mock fetch to fail to trigger mock data fallback
      vi.mocked(fetch).mockRejectedValueOnce(new Error('Network error'));

      const result = await searchPlants('rose');
      
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('Rose');
    });

    it('handles case-insensitive search', async () => {
      // Mock fetch to fail to trigger mock data fallback
      vi.mocked(fetch).mockRejectedValueOnce(new Error('Network error'));

      const result1 = await searchPlants('TOMATO');
      const result2 = await searchPlants('tomato');
      
      expect(result1).toEqual(result2);
    });

    it('returns results for valid search', async () => {
      // Mock fetch to fail to trigger mock data fallback
      vi.mocked(fetch).mockRejectedValueOnce(new Error('Network error'));

      const result = await searchPlants('tomato');
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('Tomato');
    });
  });

  describe('Mock API fallback', () => {
    it('finds calendula in mock data', async () => {
      vi.mocked(fetch).mockRejectedValueOnce(new Error('Network error'));
      
      const result = await searchPlants('calendula');
      expect(result[0].name).toBe('Calendula');
    });

    it('finds tomato in mock data', async () => {
      vi.mocked(fetch).mockRejectedValueOnce(new Error('Network error'));
      
      const result = await searchPlants('tomato');
      expect(result[0].name).toBe('Tomato');
    });

    it('finds basil in mock data', async () => {
      vi.mocked(fetch).mockRejectedValueOnce(new Error('Network error'));
      
      const result = await searchPlants('basil');
      expect(result[0].name).toBe('Basil');
    });

    it('returns empty array for unknown plants', async () => {
      vi.mocked(fetch).mockRejectedValueOnce(new Error('Network error'));
      
      const result = await searchPlants('nonexistentplant');
      expect(result).toEqual([]);
    });
  });
});
