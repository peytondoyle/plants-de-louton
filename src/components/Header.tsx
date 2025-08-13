import { Link, NavLink } from "react-router-dom";
import { useState } from "react";

interface HeaderProps {
  bedName?: string;
}

export default function Header({ bedName }: HeaderProps) {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };

  return (
    <header className="site-header" data-testid="header">
      {/* Share the same container as the page body for perfect alignment */}
      <div className="site-header__inner container">
        {/* Title - positioned on the far left */}
        <Link to="/" className="brand">
          Plants de Louton
        </Link>

        {/* Mobile menu button */}
        <button 
          className="mobile-menu-btn"
          onClick={toggleMenu}
          aria-label="Toggle navigation menu"
          aria-expanded={isMenuOpen}
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            {isMenuOpen ? (
              <path d="M18 6L6 18M6 6l12 12"/>
            ) : (
              <path d="M3 12h18M3 6h18M3 18h18"/>
            )}
          </svg>
        </button>

        {/* Section tabs (ghost pills, unified hover/focus) - positioned in the middle */}
        <nav className={`main-nav ${isMenuOpen ? 'mobile-open' : ''}`} aria-label="Sections">
          <NavLink
            to="/section/front-yard"
            className={({ isActive }) =>
              `ui-btn ui-btn--sm ui-btn--ghost ${isActive ? "is-active" : ""}`
            }
            end
            onClick={() => setIsMenuOpen(false)}
          >
            Front yard
          </NavLink>

          <NavLink
            to="/section/back-yard"
            className={({ isActive }) =>
              `ui-btn ui-btn--sm ui-btn--ghost ${isActive ? "is-active" : ""}`
            }
            end
            onClick={() => setIsMenuOpen(false)}
          >
            Back yard
          </NavLink>
        </nav>

        {/* Large white space */}
        <div style={{ flex: 1 }} />

        {/* Bed name - positioned on the far right */}
        {bedName && (
          <div className="bed-name">
            {bedName}
          </div>
        )}
      </div>

      {/* Mobile menu overlay */}
      {isMenuOpen && (
        <div className="mobile-menu-overlay" onClick={() => setIsMenuOpen(false)}>
          <div className="mobile-menu-content" onClick={(e) => e.stopPropagation()}>
            <div className="mobile-menu-header">
              <h3>Navigation</h3>
              <button 
                className="mobile-menu-close"
                onClick={() => setIsMenuOpen(false)}
                aria-label="Close menu"
              >
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M18 6L6 18M6 6l12 12"/>
                </svg>
              </button>
            </div>
            <nav className="mobile-menu-nav">
              <Link 
                to="/" 
                className="mobile-menu-item"
                onClick={() => setIsMenuOpen(false)}
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
                </svg>
                Garden Overview
              </Link>
              <Link 
                to="/section/front-yard" 
                className="mobile-menu-item"
                onClick={() => setIsMenuOpen(false)}
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                </svg>
                Front Yard
              </Link>
              <Link 
                to="/section/back-yard" 
                className="mobile-menu-item"
                onClick={() => setIsMenuOpen(false)}
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                </svg>
                Back Yard
              </Link>
            </nav>
          </div>
        </div>
      )}
    </header>
  );
}