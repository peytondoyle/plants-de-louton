import { Link, NavLink } from "react-router-dom";

interface HeaderProps {
  bedName?: string;
}

export default function Header({ bedName }: HeaderProps) {
  return (
    <header className="site-header">
      {/* Share the same container as the page body for perfect alignment */}
      <div className="site-header__inner container">
        {/* Title - positioned on the far left */}
        <Link to="/" className="brand">
          Plants de Louton
        </Link>

        {/* Section tabs (ghost pills, unified hover/focus) - positioned in the middle */}
        <nav className="main-nav" aria-label="Sections">
          <NavLink
            to="/section/front-yard"
            className={({ isActive }) =>
              `ui-btn ui-btn--sm ui-btn--ghost ${isActive ? "is-active" : ""}`
            }
            end
          >
            Front yard
          </NavLink>

          <NavLink
            to="/section/back-yard"
            className={({ isActive }) =>
              `ui-btn ui-btn--sm ui-btn--ghost ${isActive ? "is-active" : ""}`
            }
            end
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
    </header>
  );
}