import { describe, it, expect, vi, beforeEach } from 'vitest';
import { 
  createPlantDetails, 
  updatePlantDetails, 
  getPlantDetails,
  listPlantDetails,
  deletePlantDetails,
  searchPlantDetails
} from './plantDetails';
import { createMockPlantDetails } from '../test/utils';

// Mock Supabase
const mockSupabase = {
  from: vi.fn()
};

vi.mock('./supabaseClient', () => ({
  supabase: mockSupabase
}));

describe('Plant Details Functions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('createPlantDetails', () => {
    it('creates plant details successfully', async () => {
      const mockPlantDetails = createMockPlantDetails();
      const mockResponse = { data: mockPlantDetails, error: null };
      
      mockSupabase.from.mockReturnValue({
        insert: vi.fn().mockResolvedValue(mockResponse),
        select: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue(mockResponse)
        })
      });

      const result = await createPlantDetails(mockPlantDetails);
      
      expect(result).toEqual(mockPlantDetails);
      expect(mockSupabase.from).toHaveBeenCalledWith('plant_details');
    });

    it('handles creation errors', async () => {
      const mockPlantDetails = createMockPlantDetails();
      const mockError = { message: 'Database error' };
      
      mockSupabase.from.mockReturnValue({
        insert: vi.fn().mockResolvedValue({ data: null, error: mockError })
      });

      await expect(createPlantDetails(mockPlantDetails)).rejects.toThrow('Database error');
    });
  });

  describe('updatePlantDetails', () => {
    it('updates plant details successfully', async () => {
      const mockPlantDetails = createMockPlantDetails();
      const mockResponse = { data: mockPlantDetails, error: null };
      
      mockSupabase.from.mockReturnValue({
        update: vi.fn().mockResolvedValue(mockResponse),
        eq: vi.fn().mockReturnValue({
          select: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue(mockResponse)
          })
        })
      });

      const result = await updatePlantDetails('test-id', { name: 'Updated Plant' });
      
      expect(result).toEqual(mockPlantDetails);
      expect(mockSupabase.from).toHaveBeenCalledWith('plant_details');
    });

    it('handles update errors', async () => {
      const mockError = { message: 'Update failed' };
      
      mockSupabase.from.mockReturnValue({
        update: vi.fn().mockResolvedValue({ data: null, error: mockError }),
        eq: vi.fn().mockReturnValue({
          select: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({ data: null, error: mockError })
          })
        })
      });

      await expect(updatePlantDetails('test-id', { name: 'Updated Plant' })).rejects.toThrow('Update failed');
    });
  });

  describe('getPlantDetails', () => {
    it('retrieves plant details successfully', async () => {
      const mockPlantDetails = createMockPlantDetails();
      const mockResponse = { data: mockPlantDetails, error: null };
      
      mockSupabase.from.mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue(mockResponse)
          })
        })
      });

      const result = await getPlantDetails('test-id');
      
      expect(result).toEqual(mockPlantDetails);
    });

    it('returns null when plant details not found', async () => {
      mockSupabase.from.mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({ data: null, error: null })
          })
        })
      });

      const result = await getPlantDetails('nonexistent-id');
      
      expect(result).toBeNull();
    });

    it('handles retrieval errors', async () => {
      const mockError = { message: 'Retrieval failed' };
      
      mockSupabase.from.mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({ data: null, error: mockError })
          })
        })
      });

      await expect(getPlantDetails('test-id')).rejects.toThrow('Retrieval failed');
    });
  });

  describe('listPlantDetails', () => {
    it('lists plant details successfully', async () => {
      const mockPlantDetails = [createMockPlantDetails(), createMockPlantDetails()];
      const mockResponse = { data: mockPlantDetails, error: null };
      
      mockSupabase.from.mockReturnValue({
        select: vi.fn().mockResolvedValue(mockResponse)
      });

      const result = await listPlantDetails();
      
      expect(result).toEqual(mockPlantDetails);
    });

    it('returns empty array when no plant details found', async () => {
      mockSupabase.from.mockReturnValue({
        select: vi.fn().mockResolvedValue({ data: [], error: null })
      });

      const result = await listPlantDetails();
      
      expect(result).toEqual([]);
    });
  });

  describe('deletePlantDetails', () => {
    it('deletes plant details successfully', async () => {
      mockSupabase.from.mockReturnValue({
        delete: vi.fn().mockResolvedValue({ error: null }),
        eq: vi.fn().mockReturnValue({
          delete: vi.fn().mockResolvedValue({ error: null })
        })
      });

      await expect(deletePlantDetails('test-id')).resolves.not.toThrow();
    });

    it('handles deletion errors', async () => {
      const mockError = { message: 'Deletion failed' };
      
      mockSupabase.from.mockReturnValue({
        delete: vi.fn().mockResolvedValue({ error: mockError }),
        eq: vi.fn().mockReturnValue({
          delete: vi.fn().mockResolvedValue({ error: mockError })
        })
      });

      await expect(deletePlantDetails('test-id')).rejects.toThrow('Deletion failed');
    });
  });

  describe('searchPlantDetails', () => {
    it('searches plant details successfully', async () => {
      const mockPlantDetails = [createMockPlantDetails()];
      const mockResponse = { data: mockPlantDetails, error: null };
      
      mockSupabase.from.mockReturnValue({
        select: vi.fn().mockReturnValue({
          ilike: vi.fn().mockReturnValue({
            or: vi.fn().mockResolvedValue(mockResponse)
          })
        })
      });

      const result = await searchPlantDetails('tomato');
      
      expect(result).toEqual(mockPlantDetails);
    });

    it('returns empty array when no matches found', async () => {
      mockSupabase.from.mockReturnValue({
        select: vi.fn().mockReturnValue({
          ilike: vi.fn().mockReturnValue({
            or: vi.fn().mockResolvedValue({ data: [], error: null })
          })
        })
      });

      const result = await searchPlantDetails('nonexistent');
      
      expect(result).toEqual([]);
    });
  });
});



