import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import MapSectionGrid from "./components/MapSectionGrid";
import SectionIndex from "./pages/SectionIndex";
import BedDetail from "./pages/BedDetail";
import "./App.css";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<MapSectionGrid />} />
        <Route path="/section/:slug" element={<SectionIndex />} />
        <Route path="/section/:slug/bed/:bedId" element={<BedDetail />} />
        <Route path="/map/:slug" element={<Navigate to="/section/:slug" replace />} />
      </Routes>
    </BrowserRouter>
  );
}