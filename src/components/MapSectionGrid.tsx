import { mapSections } from '../data/mapSections';
import { useNavigate } from "react-router-dom";
import { useCallback, useState, useEffect } from "react";
import { listBedsBySection } from '../lib/listBedsBySection';
import SectionOnboarding from './SectionOnboarding';
import type { BedLatest } from '../types/types';

interface GardenStats {
  totalPlants: number;
  totalBeds: number;
  activeSections: number;
  recentActivity: number;
}

export default function MapSectionGrid() {
  const navigate = useNavigate();
  const [stats, setStats] = useState<GardenStats>({
    totalPlants: 0,
    totalBeds: 0,
    activeSections: 0,
    recentActivity: 0
  });
  const [loading, setLoading] = useState(true);
  const [showOnboarding, setShowOnboarding] = useState(false);

  useEffect(() => {
    const loadStats = async () => {
      try {
        console.log('Loading garden statistics...');
        
        // Load garden statistics using the correct function
        const [frontBeds, backBeds] = await Promise.all([
          listBedsBySection('front-yard'),
          listBedsBySection('back-yard')
        ]);

        console.log('Front yard beds:', frontBeds);
        console.log('Back yard beds:', backBeds);

        const totalBeds = frontBeds.length + backBeds.length;
        const totalPlants = frontBeds.reduce((sum, bed) => sum + (bed.pin_count || 0), 0) + 
                          backBeds.reduce((sum, bed) => sum + (bed.pin_count || 0), 0);
        const activeSections = [frontBeds.length, backBeds.length].filter(count => count > 0).length;

        const newStats = {
          totalPlants,
          totalBeds,
          activeSections,
          recentActivity: Math.floor(Math.random() * 5) + 1 // Placeholder for now
        };

        console.log('Calculated stats:', newStats);
        setStats(newStats);
      } catch (error) {
        console.error('Error loading garden stats:', error);
        // Set default stats if backend is not available
        setStats({
          totalPlants: 0,
          totalBeds: 0,
          activeSections: 0,
          recentActivity: 0
        });
      } finally {
        setLoading(false);
      }
    };

    loadStats();
  }, []);

  const handleClick = useCallback((slug: string) => {
    navigate(`/section/${slug}`);
  }, [navigate]);

  const handleStartOnboarding = () => {
    setShowOnboarding(true);
  };

  const handleOnboardingComplete = () => {
    setShowOnboarding(false);
    // Refresh stats after onboarding
    window.location.reload();
  };

  return (
    <>
      <div className="landing-page">
        {/* Hero Section */}
        <section className="hero-section">
          <div className="hero-content">
            <h1 className="hero-title">
              Welcome to Your Garden
            </h1>
            <p className="hero-subtitle">
              Track, manage, and nurture your plants with ease
            </p>
            
            {!loading && (
              <div className="hero-stats">
                <div className="stat-item">
                  <span className="stat-number">{stats.totalPlants}</span>
                  <span className="stat-label">Plants</span>
                </div>
                <div className="stat-item">
                  <span className="stat-number">{stats.totalBeds}</span>
                  <span className="stat-label">Beds</span>
                </div>
                <div className="stat-item">
                  <span className="stat-number">{stats.activeSections}</span>
                  <span className="stat-label">Sections</span>
                </div>
                <div className="stat-item">
                  <span className="stat-number">{stats.recentActivity}</span>
                  <span className="stat-label">Recent</span>
                </div>
              </div>
            )}

            {/* Quick Start Button */}
            {stats.totalBeds === 0 && (
              <div className="hero-cta">
                <button 
                  className="cta-button"
                  onClick={handleStartOnboarding}
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M12 5v14M5 12h14"/>
                  </svg>
                  Get Started
                </button>
                <p className="cta-subtitle">Set up your first garden section in minutes</p>
              </div>
            )}
          </div>
        </section>

        {/* Sections Grid */}
        <section className="sections-section">
          <div className="section-header">
            <h2 className="section-title">Garden Sections</h2>
            <p className="section-subtitle">Choose a section to explore your garden beds</p>
          </div>

          <div className="sections-grid">
            {mapSections.map((section) => (
              <div
                key={section.slug}
                className="section-card-modern"
                onClick={() => handleClick(section.slug)}
              >
                <div className="section-card-image">
                  <img
                    src={section.image}
                    alt={section.label}
                    className="section-image"
                  />
                  <div className="section-overlay">
                    <div className="section-overlay-content">
                      <h3 className="section-card-title">{section.label}</h3>
                      <p className="section-card-description">
                        Manage your {section.label.toLowerCase()} garden beds
                      </p>
                      <div className="section-card-arrow">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path d="M5 12h18M12 5l7 7-7 7"/>
                        </svg>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Quick Actions */}
        <section className="quick-actions-section">
          <div className="quick-actions-grid">
            <button className="quick-action-card" onClick={handleStartOnboarding}>
              <div className="quick-action-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M12 5v14M5 12h14"/>
                </svg>
              </div>
              <h3 className="quick-action-title">Add New Section</h3>
              <p className="quick-action-description">Create a new garden section</p>
            </button>

            <button className="quick-action-card" onClick={() => navigate('/section/front-yard')}>
              <div className="quick-action-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
              </div>
              <h3 className="quick-action-title">Search Plants</h3>
              <p className="quick-action-description">Find specific plants</p>
            </button>

            <button className="quick-action-card" onClick={() => navigate('/section/front-yard')}>
              <div className="quick-action-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"/>
                </svg>
              </div>
              <h3 className="quick-action-title">Care Schedule</h3>
              <p className="quick-action-description">View upcoming tasks</p>
            </button>
          </div>
        </section>
      </div>

      {/* Onboarding Modal */}
      {showOnboarding && (
        <SectionOnboarding onComplete={handleOnboardingComplete} />
      )}
    </>
  );
}