import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import PinEditorDrawer from './PinEditorDrawer';

// Mock Supabase
vi.mock('../lib/supabaseClient', () => ({
  default: {
    storage: {
      from: () => ({
        getPublicUrl: () => ({ data: { publicUrl: 'test-url' } })
      })
    }
  }
}));

// Mock backend utils
vi.mock('../lib/backend', () => ({
  backendUtils: {
    getPlantDetails: vi.fn(),
    searchPlants: vi.fn(),
    getPlantMedia: vi.fn(),
    getCareHistory: vi.fn(),
    getPlantPhotos: vi.fn(),
    uploadPlantPhoto: vi.fn(),
    deletePlantPhoto: vi.fn(),
    createCareEvent: vi.fn(),
    deleteCareEvent: vi.fn(),
    createPlantInstance: vi.fn(),
    updatePlantInstance: vi.fn(),
    deletePlantInstance: vi.fn(),
    createPin: vi.fn(),
    updatePin: vi.fn(),
    deletePin: vi.fn(),
  }
}));

// Mock the individual lib functions
vi.mock('../lib/plantDetails', () => ({
  createPlantDetails: vi.fn(),
  updatePlantDetails: vi.fn(),
  getPlantDetails: vi.fn(),
}));

vi.mock('../lib/plantInstances', () => ({
  createPlantInstance: vi.fn(),
  updatePlantInstance: vi.fn(),
  getPlantInstanceByPinId: vi.fn(),
}));

vi.mock('../lib/careEvents', () => ({
  createCareEvent: vi.fn(),
  updateCareEvent: vi.fn(),
  deleteCareEvent: vi.fn(),
  listCareEventsByPlantInstance: vi.fn(),
}));

vi.mock('../lib/pinMedia', () => ({
  uploadPinMedia: vi.fn(),
  getPinMedia: vi.fn(),
}));

vi.mock('../lib/aiPlantSearch', () => ({
  searchPlants: vi.fn(),
}));

const defaultProps = {
  open: true,
  onClose: vi.fn(),
  bedId: 'test-bed-id',
  imageId: 'test-image-id',
  initial: { x: 50, y: 50 },
  onSaved: vi.fn(),
  onDeleted: vi.fn(),
  onOpenPinGallery: vi.fn(),
};

describe('PinEditorDrawer', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders when open', () => {
    render(
      <BrowserRouter>
        <PinEditorDrawer {...defaultProps} />
      </BrowserRouter>
    );
    expect(screen.getByTestId('drawer')).toBeInTheDocument();
  });

  it('shows drawer title for new pins', () => {
    render(
      <BrowserRouter>
        <PinEditorDrawer {...defaultProps} />
      </BrowserRouter>
    );
    expect(screen.getByText('Add New Plant')).toBeInTheDocument();
  });

  it('shows edit title for existing pins', () => {
    const editProps = {
      ...defaultProps,
      initial: {
        id: 'test-id',
        name: 'Test Plant',
        bed_id: 'test-bed-id',
        image_id: 'test-image-id',
        x: 50,
        y: 50,
        notes: '',
        status: 'active' as const,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }
    };
    
    render(
      <BrowserRouter>
        <PinEditorDrawer {...editProps} />
      </BrowserRouter>
    );
    expect(screen.getByText('Edit Plant')).toBeInTheDocument();
  });

  it('starts on plant details tab for new pins', () => {
    render(
      <BrowserRouter>
        <PinEditorDrawer {...defaultProps} />
      </BrowserRouter>
    );
    
    // Plant details tab should be active for new pins
    expect(screen.getByText('Plant Details').closest('.drawer-tab')).toHaveClass('active');
  });

  it('switches to plant details tab when clicked', () => {
    render(
      <BrowserRouter>
        <PinEditorDrawer {...defaultProps} />
      </BrowserRouter>
    );
    
    // Click on plant details tab
    fireEvent.click(screen.getByText('Plant Details'));
    
    // Plant details tab should be active
    expect(screen.getByText('Plant Details').closest('.drawer-tab')).toHaveClass('active');
  });

  it('shows position information', () => {
    render(
      <BrowserRouter>
        <PinEditorDrawer {...defaultProps} />
      </BrowserRouter>
    );
    
    // Should show position display in the basic info tab
    fireEvent.click(screen.getByText('Basic Info'));
    expect(screen.getByText(/X: 50\.00, Y: 50\.00/)).toBeInTheDocument();
  });

  it('allows switching between tabs', () => {
    render(
      <BrowserRouter>
        <PinEditorDrawer {...defaultProps} />
      </BrowserRouter>
    );
    
    // Should start on plant details tab
    expect(screen.getByText('Plant Details').closest('.drawer-tab')).toHaveClass('active');
    
    // Switch to basic info tab
    fireEvent.click(screen.getByText('Basic Info'));
    expect(screen.getByText('Basic Info').closest('.drawer-tab')).toHaveClass('active');
    
    // Switch to care history tab
    fireEvent.click(screen.getByText('Care History'));
    expect(screen.getByText('Care History').closest('.drawer-tab')).toHaveClass('active');
    
    // Switch to photos tab
    fireEvent.click(screen.getByText('Photos'));
    expect(screen.getByText('Photos').closest('.drawer-tab')).toHaveClass('active');
    
    // Switch to notes tab
    fireEvent.click(screen.getByText('Notes'));
    expect(screen.getByText('Notes').closest('.drawer-tab')).toHaveClass('active');
  });

  it('calls onClose when close button is clicked', () => {
    render(
      <BrowserRouter>
        <PinEditorDrawer {...defaultProps} />
      </BrowserRouter>
    );
    
    fireEvent.click(screen.getByLabelText('Close'));
    expect(defaultProps.onClose).toHaveBeenCalled();
  });

  it('shows create button for new pins', () => {
    render(
      <BrowserRouter>
        <PinEditorDrawer {...defaultProps} />
      </BrowserRouter>
    );
    
    expect(screen.getByText('Create Plant')).toBeInTheDocument();
  });

  it('shows save button for existing pins', () => {
    const editProps = {
      ...defaultProps,
      initial: {
        id: 'test-id',
        name: 'Test Plant',
        bed_id: 'test-bed-id',
        image_id: 'test-image-id',
        x: 50,
        y: 50,
        notes: '',
        status: 'active' as const,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }
    };
    
    render(
      <BrowserRouter>
        <PinEditorDrawer {...editProps} />
      </BrowserRouter>
    );
    
    expect(screen.getByText('Save Changes')).toBeInTheDocument();
  });
});
