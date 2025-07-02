# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ecrivez-local (Write-It-Down) is a SwiftUI-based note-taking application for iOS/iPadOS that combines rich text editing, location tagging, and cloud synchronization. The app uses Core Data for local persistence and Supabase for authentication and cloud sync.

**Bundle ID**: `com.tobiasfu.write-it-down`
**Project File**: `Write-It-Down.xcodeproj`
**Minimum iOS Version**: iOS 16.0

## Build and Run Commands

```bash
# Build for iOS Simulator
xcodebuild -project Write-It-Down.xcodeproj -scheme Ecrivez-local -sdk iphonesimulator build

# Build for device (requires provisioning profile)
xcodebuild -project Write-It-Down.xcodeproj -scheme Ecrivez-local -sdk iphoneos build

# Run tests
xcodebuild test -project Write-It-Down.xcodeproj -scheme Ecrivez-local -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build
xcodebuild clean -project Write-It-Down.xcodeproj -scheme Ecrivez-local
```

## Architecture Overview

### Core Technologies
- **SwiftUI** - UI framework
- **Core Data** - Local data persistence
- **Supabase** - Authentication and cloud sync
- **RichTextKit** - Rich text editing capabilities
- **MapKit** - Location services
- **Combine** - Reactive programming for data flow

### Data Flow Architecture
1. **Local-First**: All data is saved to Core Data immediately
2. **Background Sync**: SyncManager handles bidirectional sync with Supabase
3. **Optimistic Updates**: UI updates happen immediately, sync happens asynchronously
4. **Conflict Resolution**: Last-write-wins strategy for sync conflicts

### Key Architectural Patterns
- **MVVM Pattern**: ViewModels manage business logic and state
- **Singleton Pattern**: SupabaseManager, CoreDataManager
- **Repository Pattern**: CoreDataManager acts as data repository
- **Coordinator Pattern**: OnboardingCoordinator manages onboarding flow
- **Observer Pattern**: Combine publishers for reactive updates

## Core Data Schema

### Note Entity
- `id`: UUID (primary key)
- `content`: Binary Data (NSAttributedString archived)
- `createdDate`: Date
- `updatedDate`: Date
- `location`: Transformable (CLLocationCoordinate2D)
- `locationName`: String?
- `locationLocality`: String?
- `noteType`: String
- `color`: String
- `symbol`: String
- `attachedImage`: Binary Data?
- `weather`: String
- `selectedDate`: Date?
- `isPublic`: Boolean
- `isAnonymous`: Boolean
- `userID`: String?

### Category Entity
- `id`: UUID
- `name`: String
- `color`: String (hex)
- `symbol`: String (SF Symbol name)
- `isDefault`: Boolean
- `index`: Int16 (for ordering)
- `notes`: To-Many relationship with Note

## Authentication Flow

### Supported Methods
1. **Email Magic Link** (OTP)
   - User enters email
   - OTP sent via Supabase
   - Deep link handling for auth callback

2. **Sign in with Apple**
   - Native iOS authentication
   - Nonce-based security
   - Token exchange with Supabase

### Auth State Management
- `AuthViewModel` manages authentication state
- Persists session across app launches
- Handles deep links via `onOpenURL`

## Key Components and Their Responsibilities

### ViewModels
- **AuthViewModel**: Authentication state and operations
- **NoteEditorViewModel**: Note creation/editing logic
- **NoteViewModel**: Individual note operations
- **CategoryViewModel**: Category management
- **SyncManager**: Handles Supabase synchronization

### Core Managers
- **CoreDataManager**: Core Data stack and operations
- **SupabaseManager**: Supabase client singleton
- **LocationSearchViewModel**: Location search functionality

### Main Views
- **ContentView**: Root view with tab navigation
- **HomeView**: Note list with search and filtering
- **NoteEditorView**: Rich text editor with metadata
- **SettingsView**: App settings and category management
- **OnboardingView**: First-launch experience

## Supabase Integration

### Tables
- **notes**: Mirrors Core Data Note entity
- **categories**: Mirrors Core Data Category entity

### Real-time Features
- Notes sync bidirectionally
- Public notes visible to all authenticated users
- Anonymous posting supported

### Environment Configuration
Supabase credentials are configured in `SupabaseManager.swift`:
- URL and anon key are hardcoded (consider using environment variables)

## Important Implementation Details

### Rich Text Handling
- Uses RichTextKit for editing
- Stores NSAttributedString as archived data
- Supports images, formatting, and colors

### Location Services
- Requests "When In Use" permission
- Custom location picker with map view
- Stores coordinate, name, and locality

### iPad Optimizations
- Responsive layouts using size classes
- Two-column layout for location picker on iPad
- Adjusted spacing and sizing

### Privacy Features
- Public/private note toggle
- Anonymous posting option
- Only available for authenticated users

### Onboarding Flow
- Welcome screen with Lottie animation
- Category setup
- Anonymous usage option

## Development Guidelines

### State Management
- Use `@StateObject` for ViewModels owned by a view
- Use `@ObservedObject` for ViewModels passed down
- Use `@EnvironmentObject` for app-wide state

### Core Data Best Practices
- Always use background contexts for write operations
- Implement proper error handling for save operations
- Use `NSBatchDeleteRequest` for bulk deletions

### Testing Considerations
- Test files located in `Write-It-Down-localTests/`
- Focus on ViewModel logic testing
- Mock Supabase responses for network tests

### Common Tasks

**Adding a new note property**:
1. Update Core Data model (`.xcdatamodeld`)
2. Update Note entity class
3. Add to Supabase schema
4. Update SyncManager mapping
5. Update UI in NoteEditorView

**Debugging Sign in with Apple**:
1. Check entitlements file includes capability
2. Verify provisioning profile
3. Check bundle ID matches
4. Review Console logs for auth errors
5. Ensure Associated Domains configured