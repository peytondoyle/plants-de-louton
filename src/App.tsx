import { BrowserRouter, Routes, Route, Navigate, Outlet } from "react-router-dom";
import MapSectionGrid from "./components/MapSectionGrid";
import SectionIndex from "./pages/SectionIndex";
import BedDetail from "./pages/BedDetail";
import Header from "./components/Header";
import "./App.css";

function Layout() {
  return (
    <>
      <Header />               {/* <-- Header appears once here */}
      <div className="app-shell">
        <Outlet />
      </div>
    </>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<MapSectionGrid />} />
          <Route path="/section/:slug" element={<SectionIndex />} />
          <Route path="/section/:slug/bed/:bedId" element={<BedDetail />} />
          {/* legacy redirect */}
          <Route path="/map/:slug" element={<Navigate to="/section/:slug" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}