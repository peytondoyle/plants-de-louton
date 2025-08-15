# WeatherKit Setup Guide - Fix Authentication Issues

This guide will help you fix the WeatherKit authentication error once and for all.

## Current Error
```
❌ Weather fetch error: Error Domain=WeatherDaemon.WDSJWTAuthenticatorServiceListener.Errors Code=2 "(null)"
```

## Step-by-Step Fix

### 1. Apple Developer Portal Setup

1. **Go to [developer.apple.com](https://developer.apple.com)**
2. **Navigate to Certificates, Identifiers & Profiles**
3. **Select "Identifiers" from the left sidebar**
4. **Find your App ID: `com.louton.plants`**
5. **Click on it to edit**
6. **Scroll down to "Capabilities"**
7. **Enable "WeatherKit"** ✅
8. **Click "Save"**

### 2. Xcode Project Configuration

1. **Open your project in Xcode**
2. **Select your project in the navigator**
3. **Select your target "PlantsDeLouton"**
4. **Go to "Signing & Capabilities" tab**
5. **Make sure your Team is selected**
6. **Enable "Automatically manage signing"**
7. **Click the "+" button to add capability**
8. **Search for and add "WeatherKit"**
9. **Clean and rebuild your project**

### 3. Verify Bundle Identifier

Ensure your bundle identifier matches exactly:
- **Bundle ID**: `com.louton.plants`
- **Team**: Your Apple Developer Team
- **Provisioning Profile**: Should be automatically managed

### 4. WeatherKit Authentication Key

Your WeatherKit authentication key is already in place:
- **File**: `PlantsDeLouton/WeatherKit/AuthKey_F487694PPG.p8`
- **Key ID**: `F487694PPG`
- **Team ID**: Should match your Apple Developer Team ID

### 5. Code Changes Made

The following improvements have been implemented:

#### App Initialization (`PlantsDeLoutonApp.swift`)
- Added proper WeatherKit authentication test on app launch
- Integrated LocationManager for better location handling
- Added error logging for debugging

#### Weather Service (`WeatherService.swift`)
- Added authentication testing before weather requests
- Improved location handling with fallback
- Better error handling and user feedback
- Added authentication status tracking

#### Info.plist Updates
- Enhanced location permission description
- Added WeatherKit entitlement declaration

### 6. Testing the Fix

1. **Clean your project** (Product → Clean Build Folder)
2. **Build and run** on a device (WeatherKit doesn't work in simulator)
3. **Check the console** for authentication messages:
   - ✅ Success: "WeatherKit authentication successful"
   - ❌ Failure: "WeatherKit authentication failed: [error]"

### 7. Common Issues and Solutions

#### Issue: "WeatherKit capability not found"
**Solution**: Make sure WeatherKit is added in Xcode capabilities

#### Issue: "Invalid team ID"
**Solution**: Verify your team ID matches in Apple Developer Portal

#### Issue: "Location permission denied"
**Solution**: The app will use a default location as fallback

#### Issue: "Network error"
**Solution**: Ensure device has internet connection

### 8. Verification Checklist

- [ ] WeatherKit enabled in Apple Developer Portal
- [ ] WeatherKit capability added in Xcode
- [ ] Team and bundle ID correctly configured
- [ ] Authentication key file present
- [ ] App builds without errors
- [ ] Weather data loads successfully
- [ ] Location permission granted (optional)

### 9. Debug Information

The app now provides detailed logging:
- Authentication status on app launch
- Location permission status
- Weather fetch attempts and results
- Detailed error messages

### 10. Fallback Behavior

If WeatherKit fails:
- App continues to function normally
- Weather features are disabled gracefully
- User sees appropriate error messages
- Plant care recommendations work without weather data

## Support

If you continue to experience issues after following this guide:

1. **Check the Xcode console** for detailed error messages
2. **Verify your Apple Developer account** has active membership
3. **Ensure you're testing on a physical device** (not simulator)
4. **Check your internet connection**
5. **Try deleting and reinstalling the app**

The updated code includes comprehensive error handling and fallback mechanisms to ensure your app remains functional even if WeatherKit encounters issues.
