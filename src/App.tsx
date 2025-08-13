import { BrowserRouter, Routes, Route, Navigate, Outlet, useLocation } from "react-router-dom";
import MapSectionGrid from "./components/MapSectionGrid";
import SectionIndex from "./pages/SectionIndex";
import BedDetail from "./pages/BedDetail";
import Header from "./components/Header";
import SectionOnboarding from "./components/SectionOnboarding";
import "./App.css";

function Layout() {
  const location = useLocation();
  const isBedDetail = location.pathname.includes('/bed/');
  
  // Extract bed name from URL if on bed detail page
  let bedName: string | undefined;
  if (isBedDetail) {
    // For now, we'll show a placeholder. In a real app, you'd fetch the bed data here
    bedName = "Shed bed"; // This will be dynamic once we implement proper data fetching
  }

  return (
    <>
      <Header bedName={bedName} />
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
          <Route path="/onboarding" element={<SectionOnboarding />} />
          {/* legacy redirect */}
          <Route path="/map/:slug" element={<Navigate to="/section/:slug" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}