#!/bin/bash

echo "🌤️  WeatherKit Setup Verification"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "PlantsDeLouton.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the PlantsDeLouton directory"
    exit 1
fi

echo "✅ Found Xcode project"

# Check for WeatherKit auth key
if [ -f "WeatherKit/AuthKey_F487694PPG.p8" ]; then
    echo "✅ WeatherKit authentication key found"
else
    echo "❌ WeatherKit authentication key missing"
    echo "   Expected: WeatherKit/AuthKey_F487694PPG.p8"
fi

# Check bundle identifier
BUNDLE_ID=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = com\.louton\.plants;' PlantsDeLouton.xcodeproj/project.pbxproj | head -1)
if [ ! -z "$BUNDLE_ID" ]; then
    echo "✅ Bundle identifier: com.louton.plants"
else
    echo "❌ Bundle identifier not found or incorrect"
fi

# Check Info.plist for location permission
if grep -q "NSLocationWhenInUseUsageDescription" PlantsDeLouton/PlantsDeLouton/Info.plist; then
    echo "✅ Location permission configured"
else
    echo "❌ Location permission missing from Info.plist"
fi

# Check for WeatherKit entitlement
if grep -q "WeatherKitEntitlement" PlantsDeLouton/PlantsDeLouton/Info.plist; then
    echo "✅ WeatherKit entitlement declared"
else
    echo "❌ WeatherKit entitlement missing from Info.plist"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Open Xcode and add WeatherKit capability"
echo "2. Enable WeatherKit in Apple Developer Portal"
echo "3. Build and run on a physical device"
echo "4. Check console for authentication messages"
echo ""
echo "📖 See WEATHERKIT_SETUP_GUIDE.md for detailed instructions"
