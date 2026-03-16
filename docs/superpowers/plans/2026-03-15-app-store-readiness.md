# App Store Readiness Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare the Cadence iOS app for App Store submission by adding an app icon, privacy manifest, hardcoded Supabase config, network monitoring, and auth error handling.

**Architecture:** Five independent changes to the existing MVVM + Repository codebase. A new `NetworkMonitor` service observes connectivity via `NWPathMonitor`. `SupabaseConfig` embeds keys directly with env var override for dev. `ContentView` gains error/retry state. A `PrivacyInfo.xcprivacy` declares API usage. An icon generation script produces the 1024x1024 asset.

**Tech Stack:** Swift 6.0, SwiftUI, Network framework (`NWPathMonitor`), XcodeGen, macOS CoreGraphics (icon script)

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `Scripts/generate_icon.swift` | Swift script to render 🎯 emoji as 1024x1024 PNG |
| Create | `Assets.xcassets/AppIcon.appiconset/Contents.json` | Asset catalog metadata for the app icon |
| Create | `Assets.xcassets/AppIcon.appiconset/icon_1024.png` | Generated icon image (output of script) |
| Create | `Sources/Cadence/PrivacyInfo.xcprivacy` | Privacy manifest declaring UserDefaults API usage |
| Create | `Sources/Cadence/NetworkMonitor.swift` | `NWPathMonitor` wrapper, `@Observable`, `@MainActor` |
| Modify | `Sources/Cadence/SupabaseConfig.swift` | Embed URL/key with env var override |
| Modify | `Sources/Cadence/ContentView.swift` | Add offline banner + auth error retry |
| Modify | `Sources/Cadence/DashboardView.swift` | Add offline banner overlay |
| Modify | `project.yml` | Add asset catalog source path, privacy manifest setting |
| Create | `Tests/CadenceTests/NetworkMonitorTests.swift` | Tests for NetworkMonitor |
| Create | `Tests/CadenceTests/SupabaseConfigTests.swift` | Tests for config fallback logic |

---

## Chunk 1: App Icon

### Task 1: Generate App Icon

**Files:**
- Create: `Scripts/generate_icon.swift`
- Create: `Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `Assets.xcassets/AppIcon.appiconset/icon_1024.png`

- [ ] **Step 1: Create the asset catalog JSON**

Create `Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{
  "images": [
    {
      "filename": "icon_1024.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

- [ ] **Step 2: Create the icon generation script**

Create `Scripts/generate_icon.swift` — a macOS Swift script that:
1. Creates a 1024x1024 CGContext with white background
2. Renders the 🎯 emoji centered at ~680pt font size
3. Writes the result as PNG to `Assets.xcassets/AppIcon.appiconset/icon_1024.png`

```swift
#!/usr/bin/env swift

import AppKit
import Foundation

let size = 1024
let rect = CGRect(x: 0, y: 0, width: size, height: size)

guard let context = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fprint("Failed to create context")
    exit(1)
}

// White background
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
context.fill(rect)

// Draw emoji
let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
NSGraphicsContext.current = nsContext

let emoji = "🎯" as NSString
let fontSize: CGFloat = 680
let font = NSFont.systemFont(ofSize: fontSize)
let attrs: [NSAttributedString.Key: Any] = [.font: font]
let emojiSize = emoji.size(withAttributes: attrs)
let x = (CGFloat(size) - emojiSize.width) / 2
let y = (CGFloat(size) - emojiSize.height) / 2
emoji.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)

NSGraphicsContext.current = nil

guard let image = context.makeImage() else {
    fputs("Failed to create image\n", stderr)
    exit(1)
}

let outputPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("Assets.xcassets/AppIcon.appiconset/icon_1024.png")

let dest = CGImageDestinationCreateWithURL(outputPath as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)

print("Icon generated at \(outputPath.path)")
```

- [ ] **Step 3: Run the script to generate the icon**

Run: `swift Scripts/generate_icon.swift`
Expected: "Icon generated at .../icon_1024.png" and a 1024x1024 PNG file exists.

- [ ] **Step 4: Wire asset catalog into project.yml**

Add `Assets.xcassets` to the Cadence target sources and set the `ASSETCATALOG_COMPILER_APPICON_NAME` setting:

In `project.yml`, add to Cadence target sources:
```yaml
    sources:
      - Sources/Cadence
      - App
      - Assets.xcassets
```

And add to Cadence target settings:
```yaml
      ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
```

- [ ] **Step 5: Regenerate Xcode project and verify build**

Run: `xcodegen generate && swift build`
Expected: Project generated, build succeeds.

- [ ] **Step 6: Commit**

```bash
git add Scripts/generate_icon.swift Assets.xcassets/ project.yml
git commit -m "feat: add app icon asset catalog with 🎯 emoji"
```

---

## Chunk 2: Hardcode Supabase Config

### Task 2: Embed Supabase Keys

**Files:**
- Modify: `Sources/Cadence/SupabaseConfig.swift`
- Create: `Tests/CadenceTests/SupabaseConfigTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/CadenceTests/SupabaseConfigTests.swift`:
```swift
import XCTest
@testable import Cadence

final class SupabaseConfigTests: XCTestCase {
    func testURLIsValid() {
        // Should not crash — verifies embedded config works
        let url = SupabaseConfig.url
        XCTAssertEqual(url.scheme, "https")
        XCTAssertTrue(url.host?.contains("supabase") ?? false)
    }

    func testAnonKeyIsNotEmpty() {
        let key = SupabaseConfig.anonKey
        XCTAssertFalse(key.isEmpty)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SupabaseConfigTests`
Expected: FAIL — current code uses `fatalError` when env vars are missing in test context.

- [ ] **Step 3: Update SupabaseConfig with embedded keys and env var override**

Replace `Sources/Cadence/SupabaseConfig.swift`:
```swift
import Foundation
import Supabase

enum SupabaseConfig {
    private static let defaultURL = "https://ottrmtmnndmwtkntkfaq.supabase.co"
    private static let defaultAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90dHJtdG1ubmRtd3RrbnRrZmFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2MDAxODMsImV4cCI6MjA4OTE3NjE4M30.DW0HWOvc8Huoo7ZOA10jYXSkaskr3uIrp2G3lX2dkJE"

    static let url: URL = {
        let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? defaultURL
        guard let url = URL(string: urlString) else {
            fatalError("Invalid SUPABASE_URL: \(urlString)")
        }
        return url
    }()

    static let anonKey: String = {
        let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? defaultAnonKey
        return key
    }()

    static let client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SupabaseConfigTests`
Expected: PASS

- [ ] **Step 5: Run full test suite**

Run: `swift test`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add Sources/Cadence/SupabaseConfig.swift Tests/CadenceTests/SupabaseConfigTests.swift
git commit -m "feat: embed Supabase keys with env var override for dev"
```

---

## Chunk 3: Privacy Manifest

### Task 3: Add Privacy Manifest

**Files:**
- Create: `Sources/Cadence/PrivacyInfo.xcprivacy`
- Modify: `project.yml`

- [ ] **Step 1: Create PrivacyInfo.xcprivacy**

Create `Sources/Cadence/PrivacyInfo.xcprivacy`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

The `CA92.1` reason code: "Access info from same app, per Apple docs." Supabase SDK stores auth tokens in UserDefaults.

- [ ] **Step 2: Add privacy manifest resource to project.yml**

In `project.yml`, add to the Cadence target a `resources` key that includes the privacy manifest so it gets bundled:
```yaml
    resources:
      - Sources/Cadence/PrivacyInfo.xcprivacy
```

- [ ] **Step 3: Regenerate and build**

Run: `xcodegen generate && swift build`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add Sources/Cadence/PrivacyInfo.xcprivacy project.yml
git commit -m "feat: add privacy manifest for App Store compliance"
```

---

## Chunk 4: Network Monitor + Offline Banner

### Task 4: Create NetworkMonitor

**Files:**
- Create: `Sources/Cadence/NetworkMonitor.swift`
- Create: `Tests/CadenceTests/NetworkMonitorTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/CadenceTests/NetworkMonitorTests.swift`:
```swift
import XCTest
@testable import Cadence

final class NetworkMonitorTests: XCTestCase {
    @MainActor
    func testInitialState() {
        let monitor = NetworkMonitor()
        // Before start() is called, isConnected defaults to true (optimistic)
        XCTAssertTrue(monitor.isConnected)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter NetworkMonitorTests`
Expected: FAIL — `NetworkMonitor` does not exist.

- [ ] **Step 3: Implement NetworkMonitor**

Create `Sources/Cadence/NetworkMonitor.swift`:
```swift
import Foundation
import Network
import Observation

@MainActor
@Observable
final class NetworkMonitor {
    private(set) var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter NetworkMonitorTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/Cadence/NetworkMonitor.swift Tests/CadenceTests/NetworkMonitorTests.swift
git commit -m "feat: add NetworkMonitor using NWPathMonitor"
```

### Task 5: Add Offline Banner to Dashboard

**Files:**
- Modify: `Sources/Cadence/ContentView.swift`
- Modify: `Sources/Cadence/DashboardView.swift`

- [ ] **Step 1: Update ContentView to create and pass NetworkMonitor**

Replace `Sources/Cadence/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    @State private var isReady = false
    @State private var authError: (any Error)?
    private let launcher: AppLauncher
    private let networkMonitor: NetworkMonitor

    init(launcher: AppLauncher = AppLauncher(), networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.launcher = launcher
        self.networkMonitor = networkMonitor
    }

    var body: some View {
        Group {
            if isReady {
                DashboardView(
                    habitRepository: launcher.habitRepository,
                    logRepository: launcher.logRepository,
                    networkMonitor: networkMonitor
                )
                .transition(.opacity)
            } else {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isReady)
        .task {
            networkMonitor.start()
            do {
                _ = try await launcher.launch()
            } catch {
                authError = error
            }
            isReady = true
        }
    }
}
```

- [ ] **Step 2: Update DashboardView to accept NetworkMonitor and show offline banner**

Add `networkMonitor` parameter to `DashboardView.init` and add an offline banner overlay.

In `DashboardView`, add the parameter:
```swift
private let networkMonitor: NetworkMonitor

init(habitRepository: HabitRepository, logRepository: HabitLogRepository, networkMonitor: NetworkMonitor) {
    self._viewModel = State(initialValue: DashboardViewModel(
        habitRepository: habitRepository, logRepository: logRepository
    ))
    self.networkMonitor = networkMonitor
}
```

Add an offline banner at the top of the `ScrollView` content, before the date:
```swift
if !networkMonitor.isConnected {
    HStack(spacing: 8) {
        Image(systemName: "wifi.slash")
            .font(.caption)
        Text("You're offline — habits will sync when you reconnect")
            .font(.caption)
    }
    .foregroundStyle(.secondary)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .padding(.horizontal, 16)
    .background {
        RoundedRectangle(cornerRadius: 10)
            .fill(.yellow.opacity(0.12))
    }
    .padding(.horizontal)
}
```

- [ ] **Step 3: Build and run full test suite**

Run: `swift build && swift test`
Expected: Build succeeds, all tests pass.

- [ ] **Step 4: Commit**

```bash
git add Sources/Cadence/ContentView.swift Sources/Cadence/DashboardView.swift
git commit -m "feat: add offline banner to dashboard"
```

---

## Chunk 5: Auth Error Handling

### Task 6: Show Auth Error with Retry

**Files:**
- Modify: `Sources/Cadence/ContentView.swift`

- [ ] **Step 1: Add auth error + retry state to ContentView**

Update `ContentView` to show a non-blocking error banner when auth fails and network is available. Add a retry button.

In ContentView's body, after the `isReady` transition, add an overlay when there's an auth error:

```swift
var body: some View {
    Group {
        if isReady {
            DashboardView(
                habitRepository: launcher.habitRepository,
                logRepository: launcher.logRepository,
                networkMonitor: networkMonitor
            )
            .transition(.opacity)
        } else {
            LaunchScreenView()
                .transition(.opacity)
        }
    }
    .animation(.easeInOut(duration: 0.3), value: isReady)
    .overlay(alignment: .top) {
        if isReady, authError != nil, networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Couldn't connect")
                    .font(.caption.weight(.medium))
                Spacer()
                Button("Retry") {
                    Task {
                        authError = nil
                        do {
                            _ = try await launcher.launch()
                        } catch {
                            authError = error
                        }
                    }
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.orange.opacity(0.12))
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    .task {
        networkMonitor.start()
        do {
            _ = try await launcher.launch()
        } catch {
            authError = error
        }
        isReady = true
    }
}
```

- [ ] **Step 2: Build and run full test suite**

Run: `swift build && swift test`
Expected: Build succeeds, all tests pass.

- [ ] **Step 3: Commit**

```bash
git add Sources/Cadence/ContentView.swift
git commit -m "feat: add auth error banner with retry"
```

---

## Final Verification

- [ ] **Step 1: Full build + test**

Run: `xcodegen generate && swift build && swift test`
Expected: All pass.

- [ ] **Step 2: Verify Xcode project opens and runs**

Run: `open Cadence.xcodeproj`
Verify: App builds and runs in simulator with icon visible.
