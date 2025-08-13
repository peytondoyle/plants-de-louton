# Plants de Louton

A garden management app for tracking plants, beds, and care history.

## Features

- **Garden Bed Management**: Organize plants by sections and beds
- **Plant Tracking**: Detailed plant information and care history
- **AI-Powered Plant Search**: Real-time plant data from comprehensive databases
- **Photo Management**: Track plant growth with image galleries
- **Care History**: Log watering, pruning, fertilizing, and other care events

## Setup

### Environment Variables

Create a `.env.local` file in the root directory:

```bash
# Supabase Configuration
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key

# Plant API (Optional - for real plant data)
VITE_TREFFLE_API_TOKEN=your_trefle_api_token
```

### Plant API Setup (Optional)

For real plant data fetching, you can get a free API token from:

1. **Trefle API** (Recommended): https://trefle.io/api/signup
   - Free tier: 1,000 requests/month
   - Comprehensive plant database
   - No credit card required

2. **Alternative APIs**:
   - Perenual API: https://perenual.com/docs/api
   - Plant.id API
   - Flora Incognita API

Without an API token, the app will use enhanced mock data for common garden plants.

## Development

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
```

## Database

The app uses Supabase for data storage. Run migrations in the Supabase dashboard:

1. `supabase/migrations/20250115_plant_details.sql` - Plant details and care history
2. `supabase/migrations/20250810_plant_media.sql` - Plant media management  
3. `supabase/migrations/20250811_plant_search_cache.sql` - AI search caching

## Deployment

Deploy to Vercel with automatic environment variable configuration.
