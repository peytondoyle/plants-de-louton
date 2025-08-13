# iOS App Development Technical Specification

## Overview

This document provides detailed technical specifications for developing the Plants de Louton iOS app using React Native, including architecture decisions, implementation details, and technical considerations.

---

## 1. Technology Stack

### 1.1 Core Technologies
- **React Native**: 0.72+ (latest stable)
- **TypeScript**: 5.0+ for type safety
- **Expo**: SDK 49+ for development tooling
- **React Navigation**: 6.0+ for navigation
- **React Query**: 4.0+ for data fetching and caching

### 1.2 State Management
- **Zustand**: Lightweight state management
- **React Query**: Server state management
- **AsyncStorage**: Local data persistence
- **SQLite**: Offline database storage

### 1.3 UI/UX Framework
- **React Native Elements**: UI component library
- **React Native Vector Icons**: Icon library
- **React Native Reanimated**: Smooth animations
- **React Native Gesture Handler**: Touch interactions

### 1.4 Backend Integration
- **Supabase**: Database and authentication
- **React Native Supabase**: Official client library
- **React Native NetInfo**: Network connectivity
- **React Native Background Fetch**: Background sync

---

## 2. Project Architecture

### 2.1 Directory Structure
```
src/
├── components/          # Reusable UI components
│   ├── common/         # Shared components
│   ├── forms/          # Form components
│   └── screens/        # Screen-specific components
├── screens/            # Screen components
│   ├── auth/          # Authentication screens
│   ├── garden/        # Garden management screens
│   ├── plants/        # Plant management screens
│   └── profile/       # User profile screens
├── navigation/         # Navigation configuration
├── services/          # API and external services
│   ├── supabase/      # Supabase client and queries
│   ├── ai/            # AI/ML services
│   └── storage/       # Local storage services
├── hooks/             # Custom React hooks
├── utils/             # Utility functions
├── types/             # TypeScript type definitions
├── constants/         # App constants
└── assets/            # Images, fonts, etc.
```

### 2.2 Component Architecture
```typescript
// Example component structure
interface ComponentProps {
  // Props interface
}

const Component: React.FC<ComponentProps> = ({ prop1, prop2 }) => {
  // State management
  const [state, setState] = useState();
  
  // Custom hooks
  const { data, loading } = useQuery();
  
  // Event handlers
  const handlePress = useCallback(() => {
    // Handler logic
  }, []);
  
  // Render
  return (
    <View style={styles.container}>
      {/* Component JSX */}
    </View>
  );
};

const styles = StyleSheet.create({
  // Component styles
});
```

---

## 3. Core Features Implementation

### 3.1 Authentication & User Management

#### Supabase Integration
```typescript
// services/supabase/client.ts
import { createClient } from '@supabase/supabase-js';
import AsyncStorage from '@react-native-async-storage/async-storage';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
```

#### Authentication Hook
```typescript
// hooks/useAuth.ts
import { useEffect, useState } from 'react';
import { supabase } from '../services/supabase/client';
import { User } from '@supabase/supabase-js';

export const useAuth = () => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setLoading(false);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        setUser(session?.user ?? null);
        setLoading(false);
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  return { user, loading };
};
```

### 3.2 Offline Capabilities

#### SQLite Database Setup
```typescript
// services/storage/database.ts
import * as SQLite from 'expo-sqlite';

const db = SQLite.openDatabase('plants.db');

export const initDatabase = () => {
  return new Promise((resolve, reject) => {
    db.transaction(tx => {
      // Create tables
      tx.executeSql(
        `CREATE TABLE IF NOT EXISTS plants (
          id TEXT PRIMARY KEY,
          name TEXT,
          scientific_name TEXT,
          care_data TEXT,
          created_at TEXT,
          updated_at TEXT
        )`
      );
      
      tx.executeSql(
        `CREATE TABLE IF NOT EXISTS gardens (
          id TEXT PRIMARY KEY,
          name TEXT,
          location TEXT,
          created_at TEXT
        )`
      );
    }, reject, resolve);
  });
};
```

#### Sync Service
```typescript
// services/sync/syncService.ts
import NetInfo from '@react-native-netinfo/netinfo';
import { supabase } from '../supabase/client';
import { db } from '../storage/database';

export class SyncService {
  static async syncData() {
    const netInfo = await NetInfo.fetch();
    
    if (!netInfo.isConnected) {
      return; // No sync when offline
    }

    // Sync local changes to server
    await this.syncLocalChanges();
    
    // Sync server changes to local
    await this.syncServerChanges();
  }

  static async syncLocalChanges() {
    // Implementation for syncing local changes
  }

  static async syncServerChanges() {
    // Implementation for syncing server changes
  }
}
```

### 3.3 Camera & Photo Management

#### Camera Integration
```typescript
// services/camera/cameraService.ts
import * as ImagePicker from 'expo-image-picker';
import { Camera } from 'expo-camera';

export class CameraService {
  static async requestPermissions() {
    const { status } = await Camera.requestCameraPermissionsAsync();
    return status === 'granted';
  }

  static async takePhoto() {
    const hasPermission = await this.requestPermissions();
    
    if (!hasPermission) {
      throw new Error('Camera permission not granted');
    }

    // Implementation for taking photo
  }

  static async pickFromGallery() {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [4, 3],
      quality: 0.8,
    });

    return result;
  }
}
```

#### Image Processing
```typescript
// services/ai/imageProcessing.ts
import * as ImageManipulator from 'expo-image-manipulator';

export class ImageProcessingService {
  static async processImage(uri: string) {
    // Resize image for AI processing
    const processedImage = await ImageManipulator.manipulateAsync(
      uri,
      [{ resize: { width: 512, height: 512 } }],
      { compress: 0.8, format: ImageManipulator.SaveFormat.JPEG }
    );

    return processedImage;
  }

  static async identifyPlant(imageUri: string) {
    const processedImage = await this.processImage(imageUri);
    
    // Call AI service for plant identification
    // Implementation depends on chosen AI service
  }
}
```

### 3.4 Push Notifications

#### Notification Setup
```typescript
// services/notifications/notificationService.ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';

export class NotificationService {
  static async registerForPushNotifications() {
    if (!Device.isDevice) {
      return;
    }

    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== 'granted') {
      const { status } = await Notifications.requestPermissionsAsync();
      finalStatus = status;
    }

    if (finalStatus !== 'granted') {
      return;
    }

    const token = await Notifications.getExpoPushTokenAsync();
    return token;
  }

  static async scheduleCareReminder(plantId: string, careType: string, date: Date) {
    await Notifications.scheduleNotificationAsync({
      content: {
        title: 'Plant Care Reminder',
        body: `Time to ${careType} your plant!`,
        data: { plantId, careType },
      },
      trigger: {
        date,
      },
    });
  }
}
```

---

## 4. Performance Optimization

### 4.1 Image Optimization
```typescript
// utils/imageOptimization.ts
import { Image } from 'react-native';

export const optimizeImage = (uri: string, width: number, height: number) => {
  return `${uri}?w=${width}&h=${height}&fit=crop&auto=format`;
};

export const preloadImages = (imageUris: string[]) => {
  return Promise.all(
    imageUris.map(uri => Image.prefetch(uri))
  );
};
```

### 4.2 List Performance
```typescript
// components/PlantList.tsx
import { FlatList } from 'react-native';
import { memo } from 'react';

const PlantItem = memo(({ plant }: { plant: Plant }) => {
  return (
    <View style={styles.plantItem}>
      {/* Plant item content */}
    </View>
  );
});

export const PlantList = ({ plants }: { plants: Plant[] }) => {
  const renderItem = useCallback(({ item }: { item: Plant }) => (
    <PlantItem plant={item} />
  ), []);

  const keyExtractor = useCallback((item: Plant) => item.id, []);

  return (
    <FlatList
      data={plants}
      renderItem={renderItem}
      keyExtractor={keyExtractor}
      removeClippedSubviews={true}
      maxToRenderPerBatch={10}
      windowSize={10}
      initialNumToRender={10}
    />
  );
};
```

### 4.3 Memory Management
```typescript
// hooks/useMemoryOptimization.ts
import { useEffect, useRef } from 'react';

export const useMemoryOptimization = () => {
  const mountedRef = useRef(true);

  useEffect(() => {
    return () => {
      mountedRef.current = false;
    };
  }, []);

  const safeSetState = useCallback((setter: () => void) => {
    if (mountedRef.current) {
      setter();
    }
  }, []);

  return { safeSetState };
};
```

---

## 5. Security Considerations

### 5.1 Data Encryption
```typescript
// services/security/encryption.ts
import * as Crypto from 'expo-crypto';

export class EncryptionService {
  static async encryptData(data: string, key: string): Promise<string> {
    // Implementation for data encryption
  }

  static async decryptData(encryptedData: string, key: string): Promise<string> {
    // Implementation for data decryption
  }
}
```

### 5.2 Secure Storage
```typescript
// services/storage/secureStorage.ts
import * as SecureStore from 'expo-secure-store';

export class SecureStorageService {
  static async store(key: string, value: string): Promise<void> {
    await SecureStore.setItemAsync(key, value);
  }

  static async retrieve(key: string): Promise<string | null> {
    return await SecureStore.getItemAsync(key);
  }

  static async remove(key: string): Promise<void> {
    await SecureStore.deleteItemAsync(key);
  }
}
```

---

## 6. Testing Strategy

### 6.1 Unit Testing
```typescript
// __tests__/services/plantService.test.ts
import { PlantService } from '../../services/plantService';

describe('PlantService', () => {
  it('should create a new plant', async () => {
    const plantData = {
      name: 'Test Plant',
      scientific_name: 'Testus plantus',
    };

    const result = await PlantService.createPlant(plantData);
    
    expect(result).toHaveProperty('id');
    expect(result.name).toBe(plantData.name);
  });
});
```

### 6.2 Integration Testing
```typescript
// __tests__/integration/plantManagement.test.ts
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import { PlantManagementScreen } from '../../screens/PlantManagementScreen';

describe('Plant Management Integration', () => {
  it('should add a new plant and display it in the list', async () => {
    const { getByText, getByPlaceholderText } = render(<PlantManagementScreen />);
    
    // Add new plant
    fireEvent.changeText(getByPlaceholderText('Plant name'), 'New Plant');
    fireEvent.press(getByText('Add Plant'));
    
    // Verify plant appears in list
    await waitFor(() => {
      expect(getByText('New Plant')).toBeTruthy();
    });
  });
});
```

---

## 7. Deployment & CI/CD

### 7.1 Build Configuration
```json
// app.json
{
  "expo": {
    "name": "Plants de Louton",
    "slug": "plants-de-louton",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "updates": {
      "fallbackToCacheTimeout": 0
    },
    "assetBundlePatterns": [
      "**/*"
    ],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.plantsdelouton.app"
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#FFFFFF"
      },
      "package": "com.plantsdelouton.app"
    },
    "web": {
      "favicon": "./assets/favicon.png"
    }
  }
}
```

### 7.2 EAS Build Configuration
```json
// eas.json
{
  "cli": {
    "version": ">= 3.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {}
  }
}
```

---

## 8. Monitoring & Analytics

### 8.1 Error Tracking
```typescript
// services/monitoring/errorTracking.ts
import * as Sentry from '@sentry/react-native';

export class ErrorTrackingService {
  static init() {
    Sentry.init({
      dsn: process.env.EXPO_PUBLIC_SENTRY_DSN,
      environment: __DEV__ ? 'development' : 'production',
    });
  }

  static captureError(error: Error, context?: any) {
    Sentry.captureException(error, {
      extra: context,
    });
  }
}
```

### 8.2 Analytics
```typescript
// services/analytics/analyticsService.ts
import analytics from '@react-native-firebase/analytics';

export class AnalyticsService {
  static async trackEvent(eventName: string, parameters?: object) {
    await analytics().logEvent(eventName, parameters);
  }

  static async trackScreen(screenName: string) {
    await analytics().logScreenView({
      screen_name: screenName,
      screen_class: screenName,
    });
  }
}
```

---

## 9. Performance Monitoring

### 9.1 Performance Metrics
```typescript
// services/monitoring/performanceMonitoring.ts
import { Performance } from '@react-native-firebase/perf';

export class PerformanceMonitoringService {
  static async trackScreenLoad(screenName: string) {
    const trace = await Performance.startTrace(`screen_load_${screenName}`);
    
    return {
      stop: () => trace.stop(),
    };
  }

  static async trackNetworkRequest(url: string) {
    const metric = await Performance.startTrace(`network_${url}`);
    
    return {
      stop: () => metric.stop(),
    };
  }
}
```

---

## 10. Conclusion

This technical specification provides a comprehensive foundation for developing the Plants de Louton iOS app. The architecture prioritizes:

- **Performance**: Optimized rendering and memory management
- **Offline Capabilities**: Robust offline-first design
- **Security**: Data encryption and secure storage
- **Scalability**: Modular architecture for future growth
- **User Experience**: Smooth animations and responsive design

The implementation follows React Native best practices and leverages the existing web application's business logic while adding native iOS capabilities for an enhanced mobile experience.
