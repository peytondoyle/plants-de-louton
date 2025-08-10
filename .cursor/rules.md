# AI Context Rules

## Tech Stack
- **Vite + React + TypeScript** - Modern build tooling and type safety
- **React Router (BrowserRouter)** - Client-side routing
- **Supabase client** in `src/lib` - Backend integration
- **Component-scoped CSS** - No global leakage, modular styling
- **Modern, minimal UI** - Clean, accessible design

## Image Handling
- **ImageSidebar.tsx + ImageSidebar.css** - New component for left column
- **Scrollable thumbnails** with selected state
- **Hidden file input** for image uploads
- **Main image slightly narrower** to accommodate sidebar
- **Pins panel fixed width** for consistency

## Conventions
- **Strict TypeScript** - No `any`, proper typing
- **Accessible markup** - ARIA labels, semantic HTML
- **Small utilities over heavy deps** - Minimal external packages
- **No CSS frameworks** - Custom CSS only
- **Keep file paths stable** - Avoid breaking imports

## Deployment
- **Vercel** - Hosting platform
- **SPA rewrite** - `vercel.json` with catch-all to `index.html`

## Style Guidelines
- **Match existing** card radius/shadows
- **Spacing units** - 4/8/12/16 (multiples of 4)
- **Consistent design tokens** - CSS variables for colors/spacing
