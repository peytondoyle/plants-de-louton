import { mapSections } from '../data/mapSections';
import { useNavigate } from "react-router-dom"; // Or 'next/navigation' if you're still on Next.js
import { useCallback } from "react";

export default function MapSectionGrid() {
  const navigate = useNavigate(); // If using React Router
  // const router = useRouter(); // If using Next.js (replace navigate with router.push)

  const handleClick = useCallback((slug: string) => {
    navigate(`/section/${slug}`);
  }, [navigate]);

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 p-4">
      {mapSections.map((section) => (
        <button
          key={section.slug}
          onClick={() => handleClick(section.slug)}
          className="rounded-lg overflow-hidden border shadow hover:shadow-md transition-all group"
        >
          <img
            src={section.image}
            alt={section.label}
            className="w-full h-40 object-cover group-hover:scale-105 transition-transform"
          />
          <div className="p-2 text-center font-medium text-sm">{section.label}</div>
        </button>
      ))}
    </div>
  );
}