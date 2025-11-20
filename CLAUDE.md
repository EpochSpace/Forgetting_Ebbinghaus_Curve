# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Forgetting Ebbinghaus Curve" is an iOS/macOS SwiftUI application that implements spaced repetition based on the Ebbinghaus forgetting curve. The app schedules smart notifications to help users retain information using adaptive learning algorithms that consider text complexity, length, and time of day.

## Build and Development Commands

### Building the Project
```bash
# Build for all platforms (iOS and macOS)
xcodebuild -scheme "Forgetting_Ebbinghaus_Сurve" -configuration Debug build

# Build for specific destination
xcodebuild -scheme "Forgetting_Ebbinghaus_Сurve" -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild -scheme "Forgetting_Ebbinghaus_Сurve" -destination 'platform=macOS' build
```

### Running Tests
```bash
# Run all tests
xcodebuild test -scheme "Forgetting_Ebbinghaus_Сurve" -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test target
xcodebuild test -scheme "Forgetting_Ebbinghaus_Сurve" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:Forgetting_Ebbinghaus_СurveTests

# Run UI tests
xcodebuild test -scheme "Forgetting_Ebbinghaus_Сurve" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:Forgetting_Ebbinghaus_СurveUITests
```

### Cleaning Build
```bash
xcodebuild clean -scheme "Forgetting_Ebbinghaus_Сurve"
```

## Architecture Overview

### Core Data Flow
1. **ContentView** → User interface with real-time text analysis and category detection
2. **RecallListViewModel** → Business logic coordinator, manages items and notifications
3. **ForgettingCurve** → Pure business logic for calculating spaced repetition intervals
4. **NotificationManager** → Handles system notifications and scheduling
5. **PersistenceManager** → JSON-based data persistence to local storage

### Adaptive Learning System

The app features a three-tier text categorization system:

- **Short** (<20 chars): Fast-paced intervals for quick notes (3s → 1 year, 11 intervals)
- **Medium** (20-400 chars): Standard Ebbinghaus curve (5s → 2 years, 11 intervals)
- **Long** (>400 chars): Extended intervals for complex content (10s → 3 years, 11 intervals)

**TextComplexityAnalyzer** automatically detects category based on:
- Character count (primary factor)
- Complexity score (formulas, numbers, technical terms, capitalization density)
- Mathematical symbols and scientific notation
- Acronyms and technical terminology patterns

Users can manually override detected categories via the segmented picker in ContentView.

### Smart Notification Timing

**Night Window System** (22:00-07:00):
- **NightWindow** utility checks if notifications fall during sleep hours
- **NotificationConflict** represents scheduling conflicts with night window
- When adding items at night, the system detects conflicts and offers to postpone notifications to 7 AM
- Only intervals ≥10 minutes are checked (skips 5s, 25s, 2min for immediate learning)
- Region-aware messaging based on timezone detection

### Dependency Injection Pattern

The ViewModel uses protocol-based dependency injection for testability:
```swift
init(
    notificationManager: NotificationManagerProtocol = NotificationManager.shared,
    persistenceManager: PersistenceManagerProtocol = PersistenceManager.shared
)
```

This allows mocking managers in tests while using singletons in production.

### Data Models

**RecallItem**:
- Core data structure representing a recall task
- Contains `textCategory` and `isManuallyOverridden` fields for adaptive scheduling
- Uses custom `Codable` implementation for backwards compatibility (defaults to `.medium`)

**TextCategory** enum:
- `.short`, `.medium`, `.long`
- Provides display names, descriptions, and SF Symbol icons for UI

### Notification System

**NotificationManager**:
- Implements `UNUserNotificationCenterDelegate` for foreground notifications
- Initialized in app lifecycle (`Forgetting_Ebbinghaus_urveApp.init()`)
- Uses UUID-based identifiers: `{item.id}-{timestamp}` for precise cancellation
- Supports bulk operations: cancel all, cancel by item, log pending

**Scheduling Logic**:
- Notifications scheduled using `UNCalendarNotificationTrigger` with specific date components
- Supports conflict resolution by replacing dates in the schedule (see RecallListViewModel:139-147)

### Platform-Specific Features

**macOS**:
- Multi-selection support in List with keyboard shortcuts (⌫ for delete)
- Context menu for selected items
- Custom CommandGroup for Edit menu integration

**iOS**:
- Swipe-to-delete gestures on list items
- Standard iOS confirmation dialogs

## Key Implementation Details

### Debounced Text Analysis
ContentView uses Task-based debouncing (300ms) for complexity analysis to avoid expensive calculations on every keystroke (ContentView:239-283). Provides immediate preliminary categorization, then runs full analysis after debounce.

### Backwards Compatibility
ForgettingCurve includes `@available(*, deprecated)` markers for legacy methods that don't support text categories. These will be removed in version 2.0.

### State Management
- ContentView maintains UI state for category selection, conflict alerts, and analysis details
- RecallListViewModel is `@MainActor` and uses `@Published` properties
- PersistenceManager auto-saves on every items array mutation via `didSet`

### Notification Lifecycle
1. Item created → ViewModel calculates reminder dates
2. Night window check → Detect conflicts, show alert if needed
3. User chooses → Schedule with original or postponed dates
4. Item deleted → Cancel notifications by UUID prefix matching

## Working with the Codebase

### Adding New Reminder Intervals
Modify the interval arrays in ForgettingCurve.swift (shortTextIntervals, mediumTextIntervals, longTextIntervals). Keep 11 intervals per category for consistency.

### Modifying Text Complexity Detection
Update TextComplexityAnalyzer thresholds or complexity calculation logic. The analyzer uses weighted factors (math symbols ×3, numbers ×1.5, special chars ×2, etc.).

### Changing Night Window Hours
Modify NightWindow constants: `nightStartHour` (default 22) and `morningWakeHour` (default 7).

### Data Persistence
Items are stored in Documents directory as `recall_items.json`. PersistenceManager handles encoding/decoding with error recovery (returns empty array on failure).

### Testing Notifications
Use toolbar buttons in ContentView:
- "Show Log" → Print all pending notifications to console
- "Cancel All" → Remove all scheduled notifications

## Important Notes

- The app name contains a Cyrillic 'С' in some files (Forgetting_Ebbinghaus_Сurve) - be mindful when referencing paths
- All notification scheduling respects user's system timezone
- The project targets both iOS and macOS with conditional compilation (`#if os(macOS)`)
- No external dependencies - uses only Foundation, SwiftUI, and UserNotifications frameworks
- При создании файлов, пиши в названии, как в легаси файлах, например ContentView.swift, то есть не указывай, что файл создал ты, а указывай, что его создал mac
- Старайся писать человечные комментарии к коду на английском языке

