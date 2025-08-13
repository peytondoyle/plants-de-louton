import React, { ReactElement } from 'react';
import { render, RenderOptions } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { vi } from 'vitest';

// Custom render function that includes providers
const AllTheProviders = ({ children }: { children: React.ReactNode }) => {
  return (
    <BrowserRouter>
      {children}
    </BrowserRouter>
  );
};

const customRender = (
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) => render(ui, { wrapper: AllTheProviders, ...options });

// Mock data factories
export const createMockPin = (overrides = {}) => ({
  id: 'test-pin-id',
  bed_id: 'test-bed-id',
  image_id: 'test-image-id',
  name: 'Test Plant',
  notes: 'Test notes',
  x: 100,
  y: 200,
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
  status: 'active' as const,
  ...overrides
});

export const createMockBed = (overrides = {}) => ({
  id: 'test-bed-id',
  name: 'Test Bed',
  section_id: 'test-section-id',
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
  ...overrides
});

export const createMockPlantDetails = (overrides = {}) => ({
  id: 'test-plant-details-id',
  name: 'Test Plant',
  scientific_name: 'Testus plantus',
  common_names: ['Test Plant', 'Mock Plant'],
  family: 'Testaceae',
  genus: 'Testus',
  species: 'plantus',
  cultivar: '',
  growth_habit: 'perennial' as const,
  hardiness_zones: [5, 6, 7, 8],
  sun_exposure: 'full_sun' as const,
  water_needs: 'moderate' as const,
  mature_height: 24,
  mature_width: 18,
  bloom_time: 'summer' as const,
  bloom_duration: 8,
  flower_color: ['red', 'pink'],
  foliage_color: ['green'],
  soil_type: 'well_draining' as const,
  soil_ph: 'neutral' as const,
  fertilizer_needs: 'low' as const,
  pruning_needs: 'minimal' as const,
  planting_season: 'spring' as const,
  planting_depth: 0.25,
  spacing: 12,
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
  ...overrides
});

export const createMockPlantInstance = (overrides = {}) => ({
  id: 'test-plant-instance-id',
  plant_details_id: 'test-plant-details-id',
  bed_id: 'test-bed-id',
  pin_id: 'test-pin-id',
  planted_date: '2024-01-01',
  source: 'nursery' as const,
  source_notes: 'Test source',
  cost: 10.99,
  health_status: 'good' as const,
  notes: 'Test instance notes',
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
  plant_details: createMockPlantDetails(),
  ...overrides
});

export const createMockCareEvent = (overrides = {}) => ({
  id: 'test-care-event-id',
  plant_instance_id: 'test-plant-instance-id',
  event_type: 'watering' as const,
  event_date: '2024-01-01',
  description: 'Test watering',
  notes: 'Test care notes',
  cost: 5.00,
  images: ['test-image-url'],
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
  ...overrides
});

// Mock functions
export const mockNavigate = vi.fn();
export const mockUseParams = vi.fn(() => ({}));
export const mockUseLocation = vi.fn(() => ({ 
  pathname: '/', 
  search: '', 
  hash: '', 
  state: null 
}));

// Test helpers
export const waitForLoadingToFinish = () => 
  new Promise(resolve => setTimeout(resolve, 0));

export const mockIntersectionObserver = () => {
  const mockIntersectionObserver = vi.fn();
  mockIntersectionObserver.mockReturnValue({
    observe: () => null,
    unobserve: () => null,
    disconnect: () => null,
  });
  window.IntersectionObserver = mockIntersectionObserver;
};

export const mockResizeObserver = () => {
  global.ResizeObserver = vi.fn().mockImplementation(() => ({
    observe: vi.fn(),
    unobserve: vi.fn(),
    disconnect: vi.fn(),
  }));
};

// Re-export everything
export * from '@testing-library/react';
export { customRender as render };



