# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS daily habit tracking app built with Swift 6.0 and SwiftUI, using Supabase for backend (auth, database). Supports iOS 17+ and macOS 14+. Users authenticate anonymously and track daily habit counts with streak tracking.

## Build & Test Commands

```bash
# Build (SPM)
swift build

# Build (Xcode - used for iOS app target)
xcodebuild build -scheme DailyHabitTracker -destination 'platform=iOS Simulator,name=iPhone 16'

# Regenerate Xcode project from project.yml
xcodegen generate

# Run all tests
swift test

# Run a specific test class
swift test --filter DashboardViewModelTests

# Run a single test method
swift test --filter DashboardViewModelTests/testInitialState
```

The Xcode project is generated from `project.yml` via XcodeGen. The `App/` directory contains the app entry point (`DailyHabitTrackerApp.swift`), while `Sources/DailyHabitTracker/` contains all library code. Both are compiled into the app target by Xcode, but only the library target is used by `swift build`/`swift test`.

## Architecture

**MVVM + Repository pattern:**

- **Models:** `HabitLog.swift` contains both `Habit` and `HabitLog` Codable/Sendable structs
- **Repositories:** `HabitRepository.swift` and `HabitLogRepository.swift` handle Supabase CRUD. They accept `SupabaseClient` for testability.
- **ViewModel:** `DashboardViewModel.swift` — `@Observable @MainActor` class that orchestrates repositories and exposes state to views
- **Views:** SwiftUI views (`DashboardView`, `HabitCardView`, `AddHabitView`, `HabitHistoryView`, `LaunchScreenView`, `ContentView`)
- **Services:** `AuthManager.swift` (anonymous auth), `SupabaseConfig.swift` (client init), `AppLauncher.swift` (startup orchestration)

**Data flow:** App launch → `AppLauncher` initializes auth via `AuthManager` → `ContentView` shows `LaunchScreenView` or `DashboardView` → `DashboardViewModel` uses repositories to fetch/mutate data.

**Concurrency:** Uses Swift 6 strict concurrency. All models are `Sendable`. ViewModel is `@MainActor`. Repository methods are async.

## Supabase Backend

- Config: `supabase/config.toml` (project ID: `daily-habit-tracker`)
- Migrations in `supabase/migrations/` — two tables: `habits` and `habit_logs` with Row-Level Security
- Anonymous auth enabled — no email/password flow
- Integration test scripts in `scripts/` (Python, requires `supabase` pip package)

## Dependencies

Single external dependency: `supabase-swift` (^2.0.0) via SPM, declared in both `Package.swift` and `project.yml`.
