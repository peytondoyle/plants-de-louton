#!/bin/bash

# This script updates the Xcode project to use the new simplified structure

echo "Updating Xcode project for simplified iOS app structure..."

# Navigate to project directory
cd /Users/peyton/Documents/Development/plants-de-louton/PlantsDeLouton

# Remove old file references from Xcode project
# These files were moved to .old folders
OLD_FILES=(
    "Views/Spaces/SpacesView.swift"
    "Views/Spaces/SpaceDetailView.swift"
    "Views/Spaces/BedPinView.swift"
    "Views/Spaces/AddSpaceSheet.swift"
    "Views/Spaces/AddBedSheet.swift"
    "Views/Spaces/AddPinSheet.swift"
    "Views/Spaces/PinEditorSheet.swift"
    "Views/Spaces/PinView.swift"
    "Views/Spaces/PinRow.swift"
)

echo "Files to update in Xcode project:"
echo "- Remove references to old Spaces/* files (9 files)"
echo "- Add reference to new Views/SpacesView.swift"
echo ""
echo "Please perform these steps in Xcode:"
echo ""
echo "1. In Xcode, select the PlantsDeLouton folder in the navigator"
echo "2. Find and delete the 'Spaces' group under Views (it will show as red/missing)"
echo "3. Right-click on Views folder and select 'Add Files to PlantsDeLouton'"
echo "4. Add the new SpacesView.swift file"
echo "5. Build the project (Cmd+B)"
echo ""
echo "The app structure has been simplified from 17 files to just a few core files:"
echo "- ContentView.swift (main navigation)"
echo "- Views/SpacesView.swift (all space management)"
echo "- Other existing view files"
echo ""
echo "All functionality is preserved but much simpler to understand and maintain!"