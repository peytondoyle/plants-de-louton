import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import App from './App';

// Mock React Router hooks
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return {
    ...actual,
    useLocation: vi.fn(),
    useParams: vi.fn(),
  };
});

// Mock components that might cause issues
vi.mock('./components/MapSectionGrid', () => ({
  default: () => <div data-testid="map-section-grid">Map Section Grid</div>
}));

vi.mock('./pages/SectionIndex', () => ({
  default: () => <div data-testid="section-index">Section Index</div>
}));

vi.mock('./pages/BedDetail', () => ({
  default: () => <div data-testid="bed-detail">Bed Detail</div>
}));

vi.mock('./components/SectionOnboarding', () => ({
  default: () => <div data-testid="section-onboarding">Section Onboarding</div>
}));

describe('App', () => {
  beforeEach(() => {
    // Reset mocks
    vi.clearAllMocks();
  });

  it('renders without crashing', () => {
    render(<App />);
    expect(screen.getByText('Plants de Louton')).toBeInTheDocument();
  });

  it('shows header with brand name', () => {
    render(<App />);
    expect(screen.getByText('Plants de Louton')).toBeInTheDocument();
  });

  it('renders section index on root path', () => {
    render(<App />);
    expect(screen.getByTestId('map-section-grid')).toBeInTheDocument();
  });

  it('does not show bed name in header when not on bed detail page', () => {
    render(<App />);
    // Bed name should not be present on the main page
    expect(screen.queryByTestId('bed-name')).not.toBeInTheDocument();
  });
});



