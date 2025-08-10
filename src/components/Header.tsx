import { Link, NavLink } from "react-router-dom";

export default function Header() {
  return (
    <header className="site-header">
      {/* Share the same container as the page body for perfect alignment */}
      <div className="site-header__inner container">
        {/* Brand — no internal padding so it lines up with page titles */}
        <Link to="/" className="brand">
          Plants de Louton
        </Link>

        {/* Section tabs (ghost pills, unified hover/focus) */}
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

        {/* Flex spacer pushes anything on the right edge (future utilities) */}
        <div style={{ flex: 1 }} />
      </div>
    </header>
  );
}