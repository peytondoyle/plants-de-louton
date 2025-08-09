import { NavLink } from "react-router-dom";
import { mapSections } from "../data/mapSections";

export default function Header() {
  return (
    <header className="site-header">
      <div className="site-header__inner">
        <NavLink to="/" className="brand">Plants de Louton</NavLink>

        <nav className="main-nav">
          <NavLink to="/" end className="nav-link">All sections</NavLink>
          {mapSections.slice(0, 3).map(s => (
            <NavLink key={s.slug} to={`/section/${s.slug}`} className="nav-link">
              {s.label}
            </NavLink>
          ))}
        </nav>
      </div>
    </header>
  );
}