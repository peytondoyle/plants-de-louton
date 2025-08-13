import { supabase } from "./supabaseClient";
import { PlantAPIService } from "./apiService";
import { cachedApiCall, caches } from "./cache";

export interface AIPlantSearchResult {
  name: string;
  scientific_name: string;
  common_names: string[];
  family: string;
  genus: string;
  species: string;
  growth_habit: 'annual' | 'perennial' | 'biennial' | 'shrub' | 'tree' | 'vine' | 'groundcover';
  hardiness_zones: number[];
  sun_exposure: 'full_sun' | 'partial_sun' | 'partial_shade' | 'full_shade';
  water_needs: 'low' | 'moderate' | 'high';
  mature_height: number;
  mature_width: number;
  bloom_time: 'spring' | 'summer' | 'fall' | 'winter' | 'year_round';
  bloom_duration: number;
  flower_color: string[];
  foliage_color: string[];
  soil_type: 'clay' | 'loam' | 'sandy' | 'well_draining';
  soil_ph: 'acidic' | 'neutral' | 'alkaline';
  fertilizer_needs: 'low' | 'moderate' | 'high';
  pruning_needs: 'minimal' | 'moderate' | 'heavy';
  planting_season: 'spring' | 'summer' | 'fall' | 'winter';
  planting_depth: number;
  spacing: number;
}

// Initialize plant API service
const TREFFLE_API_TOKEN = import.meta.env.VITE_TREFFLE_API_TOKEN;
const plantAPIService = TREFFLE_API_TOKEN ? new PlantAPIService(TREFFLE_API_TOKEN) : null;

export async function searchPlants(query: string): Promise<AIPlantSearchResult[]> {
  const searchTerm = query.toLowerCase().trim();

  if (!searchTerm) {
    return [];
  }

  try {
    // First check if we have cached results
    const cachedResults = await getCachedSearchResults(searchTerm);
    if (cachedResults.length > 0) {
      console.log('Using cached search results from Supabase');
      return cachedResults;
    }
  } catch (error) {
    console.log('Failed to get cached results:', error);
  }

  try {
    // Query the real plant API using enhanced service
    const apiResults = await searchPlantAPI(searchTerm);
    if (apiResults.length > 0) {
      await cacheSearchResults(searchTerm, apiResults);
      return apiResults;
    }
  } catch (error) {
    console.error('API search failed:', error);
    throw new Error('Unable to fetch plant data. Please try again.');
  }

  return [];
}

// Transform Trefle API response to our format
function transformTrefleResponse(plant: any): AIPlantSearchResult {
  return {
    name: plant.common_name || plant.scientific_name,
    scientific_name: plant.scientific_name,
    common_names: plant.common_names ? plant.common_names.split(',').map((name: string) => name.trim()) : [],
    family: plant.family || 'Unknown',
    genus: plant.genus || 'Unknown',
    species: plant.species || 'Unknown',
    growth_habit: mapGrowthHabit(plant.growth_habit),
    hardiness_zones: plant.hardiness_zones || [5, 6, 7, 8, 9],
    sun_exposure: mapSunExposure(plant.sun_exposure),
    water_needs: mapWaterNeeds(plant.water_needs),
    mature_height: plant.mature_height || 24,
    mature_width: plant.mature_width || 18,
    bloom_time: mapBloomTime(plant.bloom_time),
    bloom_duration: plant.bloom_duration || 4,
    flower_color: plant.flower_color ? [plant.flower_color] : ['Unknown'],
    foliage_color: plant.foliage_color ? [plant.foliage_color] : ['Green'],
    soil_type: mapSoilType(plant.soil_type),
    soil_ph: mapSoilPH(plant.soil_ph),
    fertilizer_needs: mapFertilizerNeeds(plant.fertilizer_needs),
    pruning_needs: mapPruningNeeds(plant.pruning_needs),
    planting_season: mapPlantingSeason(plant.planting_season),
    planting_depth: plant.planting_depth || 0.5,
    spacing: plant.spacing || 12,
  };
}

async function searchPlantAPI(query: string): Promise<AIPlantSearchResult[]> {
  // Use enhanced API service if available
  if (plantAPIService) {
    try {
      const results = await plantAPIService.searchPlants(query, 5);
      return results.map(transformTrefleResponse);
    } catch (error) {
      console.error('Enhanced API service failed, falling back to direct fetch:', error);
      // Fall back to direct fetch
    }
  }

  // Fallback to direct fetch (original implementation)
  const TREFFLE_API_TOKEN = import.meta.env.VITE_TREFFLE_API_TOKEN;
  
  if (!TREFFLE_API_TOKEN) {
    // Fallback to a mock API response for development
    console.warn('No Trefle API token found. Using mock data for development.');
    return await searchMockAPI(query);
  }

  try {
    const response = await fetch(
      `https://trefle.io/api/v1/plants/search?q=${encodeURIComponent(query)}&token=${TREFFLE_API_TOKEN}`
    );

    if (!response.ok) {
      throw new Error(`API request failed: ${response.status}`);
    }

    const data = await response.json();
    
    if (!data.data || data.data.length === 0) {
      return [];
    }

    // Transform Trefle API response to our format
    return data.data.slice(0, 5).map(transformTrefleResponse);
  } catch (error) {
    console.error('Direct API call failed:', error);
    // Fall back to mock data
    return await searchMockAPI(query);
  }
}

async function searchMockAPI(query: string): Promise<AIPlantSearchResult[]> {
  // Simulate API delay
  await new Promise(resolve => setTimeout(resolve, 800));
  
  // Enhanced mock data for common plants
  const mockPlants: { [key: string]: AIPlantSearchResult } = {
    'calendula': {
      name: "Calendula",
      scientific_name: "Calendula officinalis",
      common_names: ["Pot Marigold", "English Marigold"],
      family: "Asteraceae",
      genus: "Calendula",
      species: "officinalis",
      growth_habit: "annual",
      hardiness_zones: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      sun_exposure: "full_sun",
      water_needs: "moderate",
      mature_height: 24,
      mature_width: 12,
      bloom_time: "spring",
      bloom_duration: 16,
      flower_color: ["orange", "yellow"],
      foliage_color: ["green"],
      soil_type: "well_draining",
      soil_ph: "neutral",
      fertilizer_needs: "low",
      pruning_needs: "minimal",
      planting_season: "spring",
      planting_depth: 0.25,
      spacing: 12,
    },
    'tomato': {
      name: "Tomato",
      scientific_name: "Solanum lycopersicum",
      common_names: ["Tomato", "Love Apple"],
      family: "Solanaceae",
      genus: "Solanum",
      species: "lycopersicum",
      growth_habit: "annual",
      hardiness_zones: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      sun_exposure: "full_sun",
      water_needs: "moderate",
      mature_height: 60,
      mature_width: 24,
      bloom_time: "summer",
      bloom_duration: 12,
      flower_color: ["yellow"],
      foliage_color: ["green"],
      soil_type: "well_draining",
      soil_ph: "neutral",
      fertilizer_needs: "moderate",
      pruning_needs: "moderate",
      planting_season: "spring",
      planting_depth: 0.25,
      spacing: 24,
    },
    'basil': {
      name: "Basil",
      scientific_name: "Ocimum basilicum",
      common_names: ["Sweet Basil", "Common Basil"],
      family: "Lamiaceae",
      genus: "Ocimum",
      species: "basilicum",
      growth_habit: "annual",
      hardiness_zones: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      sun_exposure: "full_sun",
      water_needs: "moderate",
      mature_height: 18,
      mature_width: 12,
      bloom_time: "summer",
      bloom_duration: 8,
      flower_color: ["white", "pink"],
      foliage_color: ["green"],
      soil_type: "well_draining",
      soil_ph: "neutral",
      fertilizer_needs: "low",
      pruning_needs: "minimal",
      planting_season: "spring",
      planting_depth: 0.25,
      spacing: 12,
    },
    'rose': {
      name: "Rose",
      scientific_name: "Rosa",
      common_names: ["Rose", "Garden Rose"],
      family: "Rosaceae",
      genus: "Rosa",
      species: "",
      growth_habit: "shrub",
      hardiness_zones: [3, 4, 5, 6, 7, 8, 9, 10],
      sun_exposure: "full_sun",
      water_needs: "moderate",
      mature_height: 48,
      mature_width: 36,
      bloom_time: "spring",
      bloom_duration: 16,
      flower_color: ["red", "pink", "white", "yellow", "orange"],
      foliage_color: ["green"],
      soil_type: "well_draining",
      soil_ph: "neutral",
      fertilizer_needs: "moderate",
      pruning_needs: "moderate",
      planting_season: "spring",
      planting_depth: 1,
      spacing: 36,
    },
    'lavender': {
      name: "Lavender",
      scientific_name: "Lavandula angustifolia",
      common_names: ["English Lavender", "Common Lavender"],
      family: "Lamiaceae",
      genus: "Lavandula",
      species: "angustifolia",
      growth_habit: "perennial",
      hardiness_zones: [5, 6, 7, 8, 9],
      sun_exposure: "full_sun",
      water_needs: "low",
      mature_height: 24,
      mature_width: 18,
      bloom_time: "summer",
      bloom_duration: 8,
      flower_color: ["purple", "blue"],
      foliage_color: ["silver", "green"],
      soil_type: "well_draining",
      soil_ph: "alkaline",
      fertilizer_needs: "low",
      pruning_needs: "minimal",
      planting_season: "spring",
      planting_depth: 0.5,
      spacing: 18,
    },
    'sunflower': {
      name: "Sunflower",
      scientific_name: "Helianthus annuus",
      common_names: ["Common Sunflower", "Annual Sunflower"],
      family: "Asteraceae",
      genus: "Helianthus",
      species: "annuus",
      growth_habit: "annual",
      hardiness_zones: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      sun_exposure: "full_sun",
      water_needs: "moderate",
      mature_height: 120,
      mature_width: 24,
      bloom_time: "summer",
      bloom_duration: 8,
      flower_color: ["yellow"],
      foliage_color: ["green"],
      soil_type: "well_draining",
      soil_ph: "neutral",
      fertilizer_needs: "low",
      pruning_needs: "minimal",
      planting_season: "spring",
      planting_depth: 0.5,
      spacing: 24,
    },
    'mint': {
      name: "Mint",
      scientific_name: "Mentha",
      common_names: ["Mint", "Peppermint", "Spearmint"],
      family: "Lamiaceae",
      genus: "Mentha",
      species: "",
      growth_habit: "perennial",
      hardiness_zones: [3, 4, 5, 6, 7, 8, 9, 10],
      sun_exposure: "partial_sun",
      water_needs: "high",
      mature_height: 24,
      mature_width: 36,
      bloom_time: "summer",
      bloom_duration: 6,
      flower_color: ["purple", "white"],
      foliage_color: ["green"],
      soil_type: "well_draining",
      soil_ph: "neutral",
      fertilizer_needs: "low",
      pruning_needs: "minimal",
      planting_season: "spring",
      planting_depth: 0.25,
      spacing: 18,
    },
    'pepper': {
      name: "Pepper",
      scientific_name: "Capsicum annuum",
      common_names: ["Bell Pepper", "Sweet Pepper", "Capsicum"],
      family: "Solanaceae",
      genus: "Capsicum",
      species: "annuum",
      growth_habit: "annual",
      hardiness_zones: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      sun_exposure: "full_sun",
      water_needs: "moderate",
      mature_height: 36,
      mature_width: 18,
      bloom_time: "summer",
      bloom_duration: 12,
      flower_color: ["white"],
      foliage_color: ["green"],
      soil_type: "well_draining",
      soil_ph: "neutral",
      fertilizer_needs: "moderate",
      pruning_needs: "minimal",
      planting_season: "spring",
      planting_depth: 0.25,
      spacing: 18,
    },
    'zinnia': {
      name: "Zinnia",
      scientific_name: "Zinnia elegans",
      common_names: ["Common Zinnia", "Youth-and-old-age"],
      family: "Asteraceae",
      genus: "Zinnia",
      species: "elegans",
      growth_habit: "annual",
      hardiness_zones: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      sun_exposure: "full_sun",
      water_needs: "moderate",
      mature_height: 36,
      mature_width: 12,
      bloom_time: "summer",
      bloom_duration: 12,
      flower_color: ["red", "pink", "orange", "yellow", "white", "purple"],
      foliage_color: ["green"],
      soil_type: "well_draining",
      soil_ph: "neutral",
      fertilizer_needs: "low",
      pruning_needs: "minimal",
      planting_season: "spring",
      planting_depth: 0.25,
      spacing: 12,
    },
    'marigold': {
      name: "Marigold",
      scientific_name: "Tagetes",
      common_names: ["Marigold", "French Marigold", "African Marigold"],
      family: "Asteraceae",
      genus: "Tagetes",
      species: "",
      growth_habit: "annual",
      hardiness_zones: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      sun_exposure: "full_sun",
      water_needs: "moderate",
      mature_height: 24,
      mature_width: 12,
      bloom_time: "summer",
      bloom_duration: 16,
      flower_color: ["orange", "yellow", "red"],
      foliage_color: ["green"],
      soil_type: "well_draining",
      soil_ph: "neutral",
      fertilizer_needs: "low",
      pruning_needs: "minimal",
      planting_season: "spring",
      planting_depth: 0.25,
      spacing: 12,
    },
  };

  // Search through mock plants
  const results: AIPlantSearchResult[] = [];
  const searchTerm = query.toLowerCase();

  for (const [key, plant] of Object.entries(mockPlants)) {
    if (
      key.includes(searchTerm) ||
      plant.name.toLowerCase().includes(searchTerm) ||
      plant.scientific_name.toLowerCase().includes(searchTerm) ||
      plant.common_names.some(name => name.toLowerCase().includes(searchTerm))
    ) {
      results.push(plant);
    }
  }

  return results.slice(0, 5);
}

// Helper functions to map API responses to our format
function mapGrowthHabit(habit: string): AIPlantSearchResult['growth_habit'] {
  const habitMap: { [key: string]: AIPlantSearchResult['growth_habit'] } = {
    'annual': 'annual',
    'perennial': 'perennial',
    'biennial': 'biennial',
    'shrub': 'shrub',
    'tree': 'tree',
    'vine': 'vine',
    'groundcover': 'groundcover',
  };
  return habitMap[habit.toLowerCase()] || 'perennial';
}

function mapSunExposure(exposure: string): AIPlantSearchResult['sun_exposure'] {
  const exposureMap: { [key: string]: AIPlantSearchResult['sun_exposure'] } = {
    'full_sun': 'full_sun',
    'partial_sun': 'partial_sun',
    'partial_shade': 'partial_shade',
    'full_shade': 'full_shade',
    'shade': 'full_shade',
  };
  return exposureMap[exposure.toLowerCase()] || 'full_sun';
}

function mapWaterNeeds(needs: string): AIPlantSearchResult['water_needs'] {
  const needsMap: { [key: string]: AIPlantSearchResult['water_needs'] } = {
    'low': 'low',
    'moderate': 'moderate',
    'high': 'high',
  };
  return needsMap[needs.toLowerCase()] || 'moderate';
}

function mapBloomTime(time: string): AIPlantSearchResult['bloom_time'] {
  const timeMap: { [key: string]: AIPlantSearchResult['bloom_time'] } = {
    'spring': 'spring',
    'summer': 'summer',
    'fall': 'fall',
    'winter': 'winter',
    'year_round': 'year_round',
  };
  return timeMap[time.toLowerCase()] || 'summer';
}

function mapSoilType(type: string): AIPlantSearchResult['soil_type'] {
  const typeMap: { [key: string]: AIPlantSearchResult['soil_type'] } = {
    'clay': 'clay',
    'loam': 'loam',
    'sandy': 'sandy',
    'well_draining': 'well_draining',
  };
  return typeMap[type.toLowerCase()] || 'well_draining';
}

function mapSoilPH(ph: string): AIPlantSearchResult['soil_ph'] {
  const phMap: { [key: string]: AIPlantSearchResult['soil_ph'] } = {
    'acidic': 'acidic',
    'neutral': 'neutral',
    'alkaline': 'alkaline',
  };
  return phMap[ph.toLowerCase()] || 'neutral';
}

function mapFertilizerNeeds(needs: string): AIPlantSearchResult['fertilizer_needs'] {
  const needsMap: { [key: string]: AIPlantSearchResult['fertilizer_needs'] } = {
    'low': 'low',
    'moderate': 'moderate',
    'high': 'high',
  };
  return needsMap[needs.toLowerCase()] || 'low';
}

function mapPruningNeeds(needs: string): AIPlantSearchResult['pruning_needs'] {
  const needsMap: { [key: string]: AIPlantSearchResult['pruning_needs'] } = {
    'minimal': 'minimal',
    'moderate': 'moderate',
    'heavy': 'heavy',
  };
  return needsMap[needs.toLowerCase()] || 'minimal';
}

function mapPlantingSeason(season: string): AIPlantSearchResult['planting_season'] {
  const seasonMap: { [key: string]: AIPlantSearchResult['planting_season'] } = {
    'spring': 'spring',
    'summer': 'summer',
    'fall': 'fall',
    'winter': 'winter',
  };
  return seasonMap[season.toLowerCase()] || 'spring';
}

async function cacheSearchResults(query: string, results: AIPlantSearchResult[]): Promise<void> {
  try {
    const { error } = await supabase
      .from('plant_search_cache')
      .upsert({
        query: query.toLowerCase(),
        results: results,
        created_at: new Date().toISOString()
      });
    if (error) {
      console.error('Failed to cache search results:', error);
    }
  } catch (error) {
    console.error('Error caching search results:', error);
  }
}

async function getCachedSearchResults(query: string): Promise<AIPlantSearchResult[]> {
  try {
    const { data, error } = await supabase
      .from('plant_search_cache')
      .select('results')
      .eq('query', query.toLowerCase())
      .single();
    if (error || !data) {
      return [];
    }
    return data.results as AIPlantSearchResult[];
  } catch (error) {
    console.error('Error getting cached results:', error);
    return [];
  }
}
