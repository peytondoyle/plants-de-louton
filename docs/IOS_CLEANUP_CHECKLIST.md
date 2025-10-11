# iOS Codebase Cleanup Checklist

## 🎯 Priority 1: Simplify Views (Biggest Impact)

### PlantDetailView.swift (920 lines → ~200 lines)
- [ ] Extract `PlantHeaderSection` to separate file
- [ ] Extract `PlantInfoSection` to separate file  
- [ ] Extract `PlantCareSection` to separate file
- [ ] Extract `PlantPhotosSection` to separate file
- [ ] Remove complex tab system, use simple List sections
- [ ] Delete unused computed properties and methods

### GardenOverviewView.swift
- [ ] Remove redundant state variables (9 different plant/bed arrays!)
- [ ] Simplify to use single data source
- [ ] Extract weather widget to separate component
- [ ] Remove commented code

### Other Large Views
- [ ] Break down any view > 300 lines
- [ ] Extract reusable components
- [ ] Remove duplicate styling code

## 🎯 Priority 2: Remove Unnecessary Architecture

### ViewModels to Delete/Simplify
- [ ] Merge overlapping ViewModels (GardenViewModel, PlantsViewModel)
- [ ] Replace complex ViewModels with simple @State
- [ ] Remove ViewModels that just wrap API calls

### Services to Consolidate
- [ ] Merge DataService + SupabaseService → Single API layer
- [ ] Simplify WeatherService (remove mock data complexity)
- [ ] Remove NotificationService if unused

## 🎯 Priority 3: Implement New Navigation

### Current Structure (Delete)
```
ContentView.swift
├── Tab: Garden
├── Tab: Plants  
├── Tab: Beds
└── Tab: Settings
```

### New Structure (Implement)
```
ContentView.swift
├── Tab: Garden (overview)
├── Tab: Spaces (customizable sections)
├── Tab: Plants (all plants)
├── Tab: Care (tasks)
└── Tab: More (settings, etc)
```

### Steps:
- [ ] Create `Space` model
- [ ] Create `SpacesView` with list of spaces
- [ ] Create `SpaceDetailView` with beds
- [ ] Update `ContentView` tabs
- [ ] Remove old navigation code

## 🎯 Priority 4: Core Feature Implementation

### Pin System (Missing!)
- [ ] Create `PinDropperView` component
- [ ] Implement tap-to-place gesture
- [ ] Add drag-to-move functionality
- [ ] Create `PinView` with visual states
- [ ] Connect pins to plants

### Simplified Plant Management
- [ ] Create simple `PlantFormView` (< 100 lines)
- [ ] Direct Supabase saving (no complex ViewModels)
- [ ] Basic validation only

## 🎯 Priority 5: Code Quality

### File Organization
- [ ] One component per file
- [ ] Group by feature (Spaces/, Plants/, Care/)
- [ ] Delete unused files

### Code Style
- [ ] Remove all TODO comments
- [ ] Delete commented-out code
- [ ] Consistent naming conventions
- [ ] Add minimal documentation

### Dependencies
- [ ] Remove unused package dependencies
- [ ] Update to latest stable versions
- [ ] Document why each dependency exists

## 📁 New Project Structure

```
PlantsDeLouton/
├── App/
│   ├── PlantsDeLoutonApp.swift
│   └── ContentView.swift
├── Features/
│   ├── Garden/
│   │   ├── GardenView.swift
│   │   └── WeatherWidget.swift
│   ├── Spaces/
│   │   ├── Models/
│   │   │   └── Space.swift
│   │   ├── SpacesView.swift
│   │   ├── SpaceDetailView.swift
│   │   └── SpaceFormView.swift
│   ├── Plants/
│   │   ├── PlantsListView.swift
│   │   ├── PlantDetailView.swift
│   │   ├── PlantFormView.swift
│   │   └── Components/
│   │       ├── PlantHeader.swift
│   │       └── PlantInfo.swift
│   ├── Pins/
│   │   ├── PinDropperView.swift
│   │   ├── PinView.swift
│   │   └── PinSheet.swift
│   └── Care/
│       ├── CareListView.swift
│       └── CareEventForm.swift
├── Core/
│   ├── Models/
│   │   ├── Plant.swift
│   │   ├── Pin.swift
│   │   ├── Bed.swift
│   │   └── CareEvent.swift
│   ├── API/
│   │   └── PlantAPI.swift
│   └── Extensions/
└── Resources/
```

## ✅ Success Metrics

After cleanup, we should have:
- [ ] No file > 300 lines
- [ ] No more than 5 ViewModels total
- [ ] < 3 service classes
- [ ] Clear feature-based organization
- [ ] Working pin system
- [ ] All tests passing
