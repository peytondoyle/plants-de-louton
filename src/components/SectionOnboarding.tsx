import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { backendUtils } from '../lib/backend';

interface OnboardingStep {
  id: string;
  title: string;
  description: string;
  icon: string;
  component: React.ReactNode;
}

interface SectionSetup {
  name: string;
  description: string;
  type: 'front-yard' | 'back-yard' | 'garden' | 'greenhouse' | 'balcony' | 'custom';
  customType?: string;
  hasImage: boolean;
  imageFile?: File;
}

interface SectionOnboardingProps {
  onComplete?: () => void;
}

export default function SectionOnboarding({ onComplete }: SectionOnboardingProps) {
  const navigate = useNavigate();
  const [currentStep, setCurrentStep] = useState(0);
  const [sectionData, setSectionData] = useState<SectionSetup>({
    name: '',
    description: '',
    type: 'front-yard',
    hasImage: false,
  });
  const [isCreating, setIsCreating] = useState(false);

  const updateSectionData = (updates: Partial<SectionSetup>) => {
    setSectionData(prev => ({ ...prev, ...updates }));
  };

  const handleImageUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      updateSectionData({ imageFile: file, hasImage: true });
    }
  };

  const handleCreateSection = async () => {
    setIsCreating(true);
    try {
      // For now, we'll just navigate to the section
      // In a real implementation, you'd create the section in the database
      console.log('Creating section:', sectionData);
      
      // Upload image if provided
      if (sectionData.imageFile) {
        console.log('Uploading image:', sectionData.imageFile.name);
      }

      // Navigate to the new section
      navigate(`/section/${sectionData.type}`);
      
      // Call completion callback
      if (onComplete) {
        onComplete();
      }
    } catch (error) {
      console.error('Error creating section:', error);
    } finally {
      setIsCreating(false);
    }
  };

  const steps: OnboardingStep[] = [
    {
      id: 'welcome',
      title: 'Welcome to Your Garden',
      description: 'Let\'s set up your first garden section to get started',
      icon: '🌱',
      component: (
        <div className="onboarding-step-content">
          <div className="welcome-illustration">
            <div className="welcome-icon">🌱</div>
          </div>
          <h2 className="step-title">Welcome to Plants de Louton</h2>
          <p className="step-description">
            Your personal garden management companion. Let's create your first garden section 
            to start tracking and nurturing your plants.
          </p>
          <div className="feature-highlights">
            <div className="feature-item">
              <span className="feature-icon">📊</span>
              <span>Track plant growth and health</span>
            </div>
            <div className="feature-item">
              <span className="feature-icon">📅</span>
              <span>Manage care schedules</span>
            </div>
            <div className="feature-item">
              <span className="feature-icon">📸</span>
              <span>Document your garden journey</span>
            </div>
          </div>
        </div>
      )
    },
    {
      id: 'section-type',
      title: 'Choose Your Section Type',
      description: 'What type of garden area are you setting up?',
      icon: '🏡',
      component: (
        <div className="onboarding-step-content">
          <div className="section-type-grid">
            {[
              { id: 'front-yard', name: 'Front Yard', icon: '🏡', description: 'Main front garden area' },
              { id: 'back-yard', name: 'Back Yard', icon: '🌳', description: 'Back garden or patio' },
              { id: 'garden', name: 'Garden Plot', icon: '🌿', description: 'Dedicated garden space' },
              { id: 'greenhouse', name: 'Greenhouse', icon: '🏭', description: 'Protected growing space' },
              { id: 'balcony', name: 'Balcony', icon: '🏢', description: 'Apartment balcony garden' },
              { id: 'custom', name: 'Custom', icon: '✨', description: 'Other garden area' }
            ].map(type => (
              <button
                key={type.id}
                className={`section-type-card ${sectionData.type === type.id ? 'selected' : ''}`}
                onClick={() => updateSectionData({ type: type.id as any })}
              >
                <div className="section-type-icon">{type.icon}</div>
                <div className="section-type-info">
                  <h3 className="section-type-name">{type.name}</h3>
                  <p className="section-type-description">{type.description}</p>
                </div>
                {sectionData.type === type.id && (
                  <div className="selection-indicator">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M9 12l2 2 4-4"/>
                    </svg>
                  </div>
                )}
              </button>
            ))}
          </div>
          
          {sectionData.type === 'custom' && (
            <div className="custom-type-input">
              <label htmlFor="customType">Custom Section Name</label>
              <input
                id="customType"
                type="text"
                placeholder="e.g., Rooftop Garden, Community Plot"
                value={sectionData.customType || ''}
                onChange={(e) => updateSectionData({ customType: e.target.value })}
                className="custom-type-field"
              />
            </div>
          )}
        </div>
      )
    },
    {
      id: 'section-details',
      title: 'Section Details',
      description: 'Tell us about your garden section',
      icon: '📝',
      component: (
        <div className="onboarding-step-content">
          <div className="form-group">
            <label htmlFor="sectionName">Section Name</label>
            <input
              id="sectionName"
              type="text"
              placeholder="e.g., Main Garden, Vegetable Patch"
              value={sectionData.name}
              onChange={(e) => updateSectionData({ name: e.target.value })}
              className="form-input"
            />
          </div>
          
          <div className="form-group">
            <label htmlFor="sectionDescription">Description (Optional)</label>
            <textarea
              id="sectionDescription"
              placeholder="Tell us about your garden section, what you plan to grow, or any special features..."
              value={sectionData.description}
              onChange={(e) => updateSectionData({ description: e.target.value })}
              className="form-textarea"
              rows={3}
            />
          </div>
          
          <div className="form-group">
            <label className="form-label">Add a Photo (Optional)</label>
            <div className="image-upload-area">
              {sectionData.hasImage ? (
                <div className="image-preview">
                  <img 
                    src={sectionData.imageFile ? URL.createObjectURL(sectionData.imageFile) : ''} 
                    alt="Section preview" 
                  />
                  <button 
                    type="button" 
                    className="remove-image-btn"
                    onClick={() => updateSectionData({ hasImage: false, imageFile: undefined })}
                  >
                    Remove
                  </button>
                </div>
              ) : (
                <label className="image-upload-label">
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleImageUpload}
                    className="image-upload-input"
                  />
                  <div className="upload-placeholder">
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                      <polyline points="7,10 12,15 17,10"/>
                      <line x1="12" y1="15" x2="12" y2="3"/>
                    </svg>
                    <span>Click to upload a photo</span>
                    <small>JPG, PNG up to 5MB</small>
                  </div>
                </label>
              )}
            </div>
          </div>
        </div>
      )
    },
    {
      id: 'review',
      title: 'Review & Create',
      description: 'Review your section details before creating',
      icon: '✅',
      component: (
        <div className="onboarding-step-content">
          <div className="review-card">
            <div className="review-header">
              <h3>Section Summary</h3>
            </div>
            <div className="review-content">
              <div className="review-item">
                <span className="review-label">Type:</span>
                <span className="review-value">
                  {sectionData.type === 'custom' ? sectionData.customType : 
                   sectionData.type.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                </span>
              </div>
              <div className="review-item">
                <span className="review-label">Name:</span>
                <span className="review-value">{sectionData.name || 'Not specified'}</span>
              </div>
              {sectionData.description && (
                <div className="review-item">
                  <span className="review-label">Description:</span>
                  <span className="review-value">{sectionData.description}</span>
                </div>
              )}
              <div className="review-item">
                <span className="review-label">Photo:</span>
                <span className="review-value">
                  {sectionData.hasImage ? '✓ Added' : 'No photo'}
                </span>
              </div>
            </div>
          </div>
          
          <div className="next-steps">
            <h4>What's Next?</h4>
            <div className="next-steps-list">
              <div className="next-step-item">
                <span className="next-step-icon">1</span>
                <span>Create your first garden bed</span>
              </div>
              <div className="next-step-item">
                <span className="next-step-icon">2</span>
                <span>Add plants to your bed</span>
              </div>
              <div className="next-step-item">
                <span className="next-step-icon">3</span>
                <span>Start tracking growth and care</span>
              </div>
            </div>
          </div>
        </div>
      )
    }
  ];

  const canProceed = () => {
    switch (currentStep) {
      case 0: return true; // Welcome step
      case 1: return sectionData.type && (sectionData.type !== 'custom' || sectionData.customType);
      case 2: return sectionData.name.trim().length > 0;
      case 3: return true; // Review step
      default: return false;
    }
  };

  const handleNext = () => {
    if (currentStep < steps.length - 1 && canProceed()) {
      setCurrentStep(currentStep + 1);
    }
  };

  const handleBack = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleSkip = () => {
    if (onComplete) {
      onComplete();
    } else {
      navigate('/');
    }
  };

  return (
    <div className="onboarding-overlay">
      <div className="onboarding-modal">
        <div className="onboarding-header">
          <button 
            className="skip-btn" 
            onClick={handleSkip}
            disabled={isCreating}
          >
            Skip for now
          </button>
        </div>

        <div className="onboarding-progress">
          <div className="progress-bar">
            <div 
              className="progress-fill" 
              style={{ width: `${((currentStep + 1) / steps.length) * 100}%` }}
            />
          </div>
          <div className="progress-text">
            Step {currentStep + 1} of {steps.length}
          </div>
        </div>

        <div className="onboarding-content">
          <div className="step-header">
            <div className="step-icon">{steps[currentStep].icon}</div>
            <div className="step-info">
              <h1 className="step-title">{steps[currentStep].title}</h1>
              <p className="step-description">{steps[currentStep].description}</p>
            </div>
          </div>

          <div className="step-body">
            {steps[currentStep].component}
          </div>
        </div>

        <div className="onboarding-footer">
          <div className="footer-actions">
            {currentStep > 0 && (
              <button 
                className="btn btn-secondary" 
                onClick={handleBack}
                disabled={isCreating}
              >
                Back
              </button>
            )}
            
            <div className="footer-spacer" />
            
            {currentStep < steps.length - 1 ? (
              <button 
                className="btn btn-primary" 
                onClick={handleNext}
                disabled={!canProceed() || isCreating}
              >
                Continue
              </button>
            ) : (
              <button 
                className="btn btn-primary" 
                onClick={handleCreateSection}
                disabled={!canProceed() || isCreating}
              >
                {isCreating ? (
                  <>
                    <div className="spinner spinner--sm" />
                    Creating...
                  </>
                ) : (
                  'Create Section'
                )}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
