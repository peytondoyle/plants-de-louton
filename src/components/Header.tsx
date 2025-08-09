import { Link, NavLink } from "react-router-dom";

export default function Header() {
  return (
    <header className="site-header">
      <div className="site-header__inner">
        <Link to="/" className="brand">Plants de Louton</Link>

        {/* Top nav as ghost pills, unified hover/focus */}
        <nav className="main-nav" aria-label="Sections">
        <NavLink
          to="/section/front-yard"
          className={({ isActive }) =>
            `ui-btn ui-btn--sm ui-btn--ghost ${isActive ? "is-active" : ""}`
          }
        >
          Front yard
        </NavLink>
        <NavLink
          to="/section/back-yard"
          className={({ isActive }) =>
            `ui-btn ui-btn--sm ui-btn--ghost ${isActive ? "is-active" : ""}`
          }
        >
          Back yard
        </NavLink>
        </nav>

        {/* right side utility (leave empty for now) */}
        <div style={{ marginLeft: "auto" }} />
      </div>
    </header>
  );
}