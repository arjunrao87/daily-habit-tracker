# Cadence

iOS daily habit tracking app built with Swift 6.0 and SwiftUI. Users authenticate anonymously and track daily habit counts with streak tracking.

**Stack:** Swift 6.0, SwiftUI, Supabase (auth + database), Swift Package Manager, XcodeGen

**Platforms:** iOS 17+, macOS 14+

## Prerequisites

- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (for local backend development)
- Python 3 with `supabase` package (optional, for integration test scripts)

## Getting Started

1. **Clone the repo:**

   ```bash
   git clone https://github.com/arjunrao87/daily-habit-tracker.git
   cd daily-habit-tracker
   ```

2. **Generate the Xcode project:**

   ```bash
   xcodegen generate
   ```

3. **Start the local Supabase instance:**

   ```bash
   supabase start
   ```

   This runs migrations from `supabase/migrations/` automatically.

4. **Set environment variables** for the Supabase URL and anon key. These are configured in `project.yml` under the scheme's environment variables and will be picked up at runtime via `ProcessInfo.processInfo.environment`. Update them if you're pointing at a different Supabase instance.

5. **Build and run** in Xcode using the `Cadence` scheme, targeting an iOS 17+ simulator.

## Build & Test

```bash
# Build via SPM (library target only)
swift build

# Build the full app via Xcode
xcodebuild build -scheme Cadence -destination 'platform=iOS Simulator,name=iPhone 16'

# Run all tests
swift test

# Run a specific test class
swift test --filter DashboardViewModelTests

# Run a single test method
swift test --filter DashboardViewModelTests/testInitialState

# Regenerate Xcode project after changing project.yml
xcodegen generate
```

The Xcode project is generated from `project.yml` via XcodeGen. The `App/` directory contains the app entry point (`CadenceApp.swift`), while `Sources/Cadence/` contains all library code. Both are compiled into the app target by Xcode, but only the library target is used by `swift build` / `swift test`.

## Architecture

**MVVM + Repository pattern**

```
App/
  CadenceApp.swift          # App entry point
Sources/Cadence/
  Models/
    HabitLog.swift           # Habit and HabitLog structs (Codable, Sendable)
  Repositories/
    HabitRepository.swift    # Supabase CRUD for habits
    HabitLogRepository.swift # Supabase CRUD for habit logs
  ViewModels/
    DashboardViewModel.swift # @Observable @MainActor, orchestrates repositories
  Views/
    DashboardView.swift      # Main habit dashboard
    HabitCardView.swift      # Individual habit card
    AddHabitView.swift       # Create new habit
    HabitHistoryView.swift   # Calendar-based history
    LaunchScreenView.swift   # Launch/splash screen
    ContentView.swift        # Root view (auth gating)
  Services/
    AuthManager.swift        # Anonymous authentication
    SupabaseConfig.swift     # Supabase client initialization
    AppLauncher.swift        # Startup orchestration
    NetworkMonitor.swift     # Network connectivity monitoring
```

**Data flow:** App launch → `AppLauncher` initializes auth via `AuthManager` → `ContentView` shows `LaunchScreenView` or `DashboardView` → `DashboardViewModel` uses repositories to fetch/mutate data.

**Concurrency:** Uses Swift 6 strict concurrency. All models are `Sendable`. ViewModel is `@MainActor`. Repository methods are async.

## Supabase Backend

- **Config:** `supabase/config.toml` (project ID: `cadence`)
- **Migrations:** `supabase/migrations/` — two tables: `habits` and `habit_logs` with Row-Level Security
- **Auth:** Anonymous auth enabled (no email/password flow)
- **Integration tests:** Python scripts in `scripts/` (require `supabase` pip package)

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [supabase-swift](https://github.com/supabase/supabase-swift) | ^2.0.0 | Supabase client (auth, database) |

## Project Structure

| Path | Purpose |
|------|---------|
| `App/` | App entry point |
| `Sources/Cadence/` | All library/app source code |
| `Tests/CadenceTests/` | Unit tests |
| `Assets.xcassets/` | App icon and asset catalog |
| `supabase/` | Supabase config and migrations |
| `scripts/` | Utility and integration test scripts |
| `project.yml` | XcodeGen project definition |
| `Package.swift` | SPM package definition |

## License

All rights reserved.
