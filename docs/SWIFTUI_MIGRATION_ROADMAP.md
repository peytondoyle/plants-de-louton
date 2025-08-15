# SwiftUI Migration Roadmap

## Phase 1: Foundation ✅ COMPLETE
- [x] Create SwiftUI app scaffold with Xcode project structure
- [x] Set up basic navigation and tab structure
- [x] Create core data models (Plant, Bed, CareEvent)
- [x] Implement basic UI components

## Phase 2: Core Features ✅ COMPLETE

### Phase 2a: Basic UI ✅ COMPLETE
- [x] Create Garden Overview view with hero card
- [x] Implement Plants list view
- [x] Add basic navigation between views
- [x] Create Settings view placeholder

### Phase 2b: Supabase Integration ✅ COMPLETE
- [x] Add Supabase Swift package to Xcode project
- [x] Configure Supabase credentials and environment
- [x] Create SupabaseService for database operations
- [x] Implement authentication with Sign in with Apple
- [x] Connect to real Supabase backend
- [x] Test app with real database connection

### Phase 2c: Bed Management ✅ COMPLETE
- [x] Create BedsListView to display garden beds
- [x] Create BedDetailView to show bed information and assigned plants
- [x] Create BedsViewModel for state management
- [x] Update data models to use pins table (plants with coordinates)
- [x] Implement plant-to-bed assignment functionality
- [x] Connect bed management to Supabase backend

### Phase 2d: Plant Details & AI Search ✅ COMPLETE
- [x] Create PlantDetailsView with form interface
- [x] Implement AI plant search integration
- [x] Create PlantSearchSheet for search results
- [x] Add plant creation and editing functionality
- [x] Connect plant details to Supabase backend

### Phase 2e: Dashboard & Navigation Enhancement ✅ COMPLETE
- [x] Implement real weather data with Apple WeatherKit
- [x] Create dynamic Dashboard with real plant/bed counts
- [x] Add section-based navigation (Front yard, Back yard, Side yard)
- [x] Implement color consistency throughout navigation hierarchy
- [x] Add care reminders and weather integration
- [x] Create section detail views with bed and plant listings
- [x] Implement consistent typography and visual design

## Phase 3: UX Polish & Usability 🎯 CURRENT

### Phase 3a: User Experience Improvements
- [ ] Display user info and sign-in method in Settings
- [ ] Make care reminders interactive (link to plant detail)
- [ ] Introduce collapsible sections on Dashboard
- [ ] Update plant list to show edit icon instead of repetitive text
- [ ] Add empty state illustrations
- [ ] Replace "Tap to add details" with edit icons
- [ ] Add sorting/filtering for plant and bed lists

### Phase 3b: Visual Enhancements
- [ ] Add plant thumbnails or icons in bed detail lists
- [ ] Compact AI Discovery card with expand/collapse
- [ ] Subtle animations for list updates and quick actions
- [ ] Enhanced empty states with illustrations

## Phase 4: Advanced Features

### Phase 4a: Garden Visualization
- [ ] Create interactive garden map view
- [ ] Implement drag-and-drop plant placement
- [ ] Add visual bed layout with plant positions
- [ ] Create garden overview with statistics

### Phase 4b: Care Management
- [ ] Implement care event tracking
- [ ] Add watering and fertilizing schedules
- [ ] Create care history view
- [ ] Add care reminders and notifications

### Phase 4c: Plant Health & Monitoring
- [ ] Add plant health status tracking
- [ ] Implement photo upload for plants
- [ ] Create plant growth tracking
- [ ] Add disease and pest monitoring

## Phase 5: Power Features
- [ ] Search and filter for plant list and bed list
- [ ] Sorting options for plants (alphabetical, last updated, care needs)
- [ ] Offline mode for viewing/editing plant data without connection
- [ ] Local caching of images and plant data

## Phase 6: Engagement & Notifications
- [ ] Push notifications for upcoming care tasks (watering, pruning)
- [ ] Weather-triggered care suggestions
- [ ] In-app tips based on AI plant analysis

## Phase 7: Advanced AI & Automation
- [ ] AI auto-tagging for plant photos (identify plant type, health status)
- [ ] AI-generated care schedules based on plant type and season
- [ ] Batch updates (e.g., "Mark all watered" after a rain event)

## Phase 8: Polish & Optimization
- [ ] Optimize performance and loading times
- [ ] Add comprehensive error handling
- [ ] Implement offline support
- [ ] Add data export/import functionality
- [ ] Create comprehensive test suite

## Technical Implementation Notes

### Data Models
The app uses the following data models that align with the Supabase database schema:

- **Plant**: Represents plants stored in the `pins` table with coordinates (x, y) and bed association
- **Bed**: Represents garden beds with name and section information
- **CareEvent**: Represents plant care activities (future implementation)

### Database Schema
- **pins**: Main table for plants with coordinates and bed association
- **beds**: Garden bed information
- **plant_search_cache**: Cached AI search results
- **bed_plants**: Join table for plant-to-bed assignments (deprecated in favor of pins table)

### Authentication
- Sign in with Apple integration
- Supabase Row Level Security (RLS) policies
- User-specific data access

### Color System
- **Front yard**: Green theme throughout navigation
- **Back yard**: Blue theme throughout navigation  
- **Side yard**: Orange theme throughout navigation
- Consistent color flow from dashboard to detail views

### Current Navigation Structure
```swift
TabView {
    // Garden Tab
    NavigationStack {
        GardenOverviewView() // Dashboard with sections
    }
    .tabItem {
        Image(systemName: "house.fill")
        Text("Garden")
    }
    
    // Plants Tab
    NavigationStack {
        PlantsView()
    }
    .tabItem {
        Image(systemName: "leaf")
        Text("Plants")
    }
    
    // Beds Tab
    NavigationStack {
        BedsListView()
    }
    .tabItem {
        Image(systemName: "square.grid.2x2")
        Text("Beds")
    }
    
    // Settings Tab
    NavigationStack {
        SettingsView()
    }
    .tabItem {
        Image(systemName: "gear")
        Text("Settings")
    }
}
```

## Development Status

**Current Phase**: Phase 3a - UX Polish & Usability
**Next Milestone**: User experience improvements based on feedback
**Database**: Connected to Supabase with real data
**Authentication**: Sign in with Apple working
**Core Features**: Plant management, bed management, AI search, weather integration all functional
**Recent Achievements**: 
- ✅ Complete color consistency throughout navigation
- ✅ Real weather data integration with Apple WeatherKit
- ✅ Dynamic dashboard with section-based navigation
- ✅ Consistent typography and visual design
- ✅ Section detail views with bed and plant listings

## Feedback Integration Status

### Immediate Priorities (Phase 3a)
- [x] **Settings Enhancement**: Display user info and sign-in method
- [ ] **Interactive Care Reminders**: Link to plant detail views
- [x] **Plant List UX**: Replace "Tap to add details" with edit icons
- [ ] **Empty States**: Add illustrated empty state screens
- [ ] **Dashboard Polish**: Consider collapsible sections
