# Plants de Louton - Project Overview

A unified garden management ecosystem with web and mobile applications sharing the same backend and design system.

## 🏗️ **Repository Structure**

```
plants-de-louton/                    # Main repository
├── src/                            # React web application
│   ├── components/                 # React components
│   ├── pages/                     # Web pages
│   ├── lib/                       # Web services
│   └── styles/                    # Web styles
├── PlantsDeLouton/                # SwiftUI iOS application
│   ├── Package.swift              # Swift Package Manager
│   ├── PlantsDeLouton/            # iOS app source
│   └── README.md                  # iOS documentation
├── docs/                          # Shared documentation
│   ├── SWIFTUI_MIGRATION_ROADMAP.md
│   └── API_DOCUMENTATION.md
├── supabase/                      # Shared database
│   └── migrations/                # Database schema
├── public/                        # Web assets
├── .github/                       # CI/CD workflows
├── README.md                      # Main project overview
└── .gitignore                     # Unified ignore patterns
```

## 🎯 **Why Unified Repository?**

### **Single Product, Multiple Platforms**
- **Shared business logic** and data models
- **Consistent user experience** across platforms
- **Coordinated feature releases**
- **Simplified project management**

### **Development Benefits**
- **Atomic commits** affecting both platforms
- **Shared configuration** and environment variables
- **Unified testing** and CI/CD pipelines
- **Easier dependency management**

### **Team Collaboration**
- **Single source of truth** for all code
- **Shared documentation** and project history
- **Coordinated releases** and versioning
- **Simplified onboarding** for new team members

## 📱 **Platforms**

### **Web Application (React/TypeScript)**
- **Technology**: React, TypeScript, Vite
- **Deployment**: Vercel
- **Features**: Full garden management interface
- **Status**: ✅ Production ready

### **iOS Application (SwiftUI)**
- **Technology**: SwiftUI, Core Data, Supabase
- **Deployment**: App Store / TestFlight
- **Features**: Native iOS garden management
- **Status**: 🚧 In development (Phase 1-2 complete)

## 🔗 **Shared Resources**

### **Backend (Supabase)**
- **Database**: PostgreSQL with real-time subscriptions
- **Authentication**: Supabase Auth
- **Storage**: File uploads for plant images
- **API**: REST and GraphQL endpoints

### **Design System**
- **Colors**: Blue to purple gradients
- **Typography**: System fonts with consistent hierarchy
- **Components**: Card-based layouts
- **Spacing**: 16px/24px grid system

### **Data Models**
- **Plants**: Core garden entities
- **Beds**: Garden bed management
- **Care Events**: Maintenance tracking
- **Images**: Photo management

## 🚀 **Development Workflow**

### **Web Development**
```bash
cd src/
npm install
npm run dev
```

### **iOS Development**
```bash
cd PlantsDeLouton/
swift build
# Open in Xcode for iOS development
```

### **Shared Development**
```bash
# Update shared documentation
git add docs/
git commit -m "docs: update API documentation"

# Update both platforms
git add src/ PlantsDeLouton/
git commit -m "feat: add new plant search feature"
```

## 📋 **Version Management**

### **Release Strategy**
- **Web**: Semantic versioning with Vercel deployments
- **iOS**: App Store releases with TestFlight beta testing
- **Database**: Migrations applied to production Supabase

### **Branch Strategy**
```
main                    # Production-ready code
├── develop            # Integration branch
├── feature/web-*      # Web feature branches
├── feature/ios-*      # iOS feature branches
└── release/*          # Release preparation
```

## 🔧 **Configuration**

### **Environment Variables**
```bash
# Shared across platforms
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_key

# Platform-specific
# Web: .env files in src/
# iOS: Configuration in PlantsDeLouton/
```

### **Dependencies**
- **Web**: npm packages in `package.json`
- **iOS**: Swift Package Manager in `Package.swift`
- **Shared**: Supabase SDK for both platforms

## 🧪 **Testing Strategy**

### **Web Testing**
- **Unit Tests**: Vitest for component testing
- **E2E Tests**: Playwright for user flows
- **API Tests**: Supabase integration testing

### **iOS Testing**
- **Unit Tests**: XCTest for business logic
- **UI Tests**: XCUITest for user interface
- **Integration Tests**: Core Data and Supabase testing

## 📦 **Deployment**

### **Web Deployment**
- **Platform**: Vercel
- **Branch**: `main` auto-deploys
- **Preview**: Feature branch deployments

### **iOS Deployment**
- **Platform**: App Store Connect
- **Beta**: TestFlight for testing
- **Production**: App Store releases

## 🤝 **Contributing**

### **Development Setup**
1. **Clone repository**
2. **Set up web environment** (`cd src/ && npm install`)
3. **Set up iOS environment** (`cd PlantsDeLouton/ && swift build`)
4. **Configure Supabase** (shared environment variables)

### **Code Standards**
- **Web**: ESLint + Prettier
- **iOS**: SwiftLint
- **Documentation**: Markdown with consistent formatting
- **Commits**: Conventional commit messages

## 📈 **Future Roadmap**

### **Phase 1: Foundation** ✅
- [x] Web application (React/TypeScript)
- [x] iOS foundation (SwiftUI/Core Data)
- [x] Shared backend (Supabase)

### **Phase 2: Feature Parity** 🚧
- [ ] AI plant search (both platforms)
- [ ] Advanced garden management
- [ ] Real-time collaboration

### **Phase 3: Platform Expansion**
- [ ] Android application
- [ ] Desktop application
- [ ] Smart home integration

## 🎉 **Benefits of This Structure**

1. **Simplified Management**: One repository for all platforms
2. **Shared Resources**: Common backend, design, and documentation
3. **Coordinated Development**: Features developed across platforms
4. **Consistent Experience**: Same data and functionality everywhere
5. **Easier Maintenance**: Single source of truth for business logic

---

**This unified approach ensures Plants de Louton provides a consistent, powerful garden management experience across all platforms while maintaining development efficiency and code quality.**
