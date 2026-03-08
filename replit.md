# Portal - iOS App Signer

## Overview
Portal is a native iOS/iPadOS application built with Swift and SwiftUI. It's a powerful app signer and installer that lets users sign, manage, and install applications directly on their iOS devices. All signing happens locally on the device - no external servers required.

**Important**: This is a native iOS app that requires Xcode on macOS to build. The source code cannot be compiled or run directly in the Replit environment since Xcode is not available on Linux.

## Project Structure
- `Feather/` - Main Swift application source code
  - `Views/` - SwiftUI views
  - `Backend/` - Backend logic
  - `Extensions/` - Swift extensions
  - `Utilities/` - Utility functions
  - `Resources/` - App resources and assets
- `Feather.xcodeproj/` - Xcode project configuration
- `Zsign/` - Code signing library
- `NimbleKit/` - Swift library
- `AltSourceKit/` - Source management
- `IDeviceKitten/` - Device communication
- `files/` - Supporting files
- `public/` - Web landing page (for Replit)
- `server.js` - Node.js server for the landing page

## Replit Setup
Since this is an iOS-only project, Replit hosts a landing page that:
- Displays project information and features
- Links to the official GitHub releases
- Provides download links for the IPA file

## Building the iOS App
To build the actual iOS app, you need:
1. A Mac with Xcode installed
2. Clone the repository
3. Run `make deps` to download dependencies
4. Run `make` to build the IPA

## Technology Stack
- **iOS App**: Swift, SwiftUI
- **Landing Page**: Node.js, HTML, CSS
- **Build System**: Makefile, xcodebuild

## Recent Changes
- **UI Modernization Pass**: Comprehensive visual updates across multiple views:
  - InstallPreviewView/InstallProgressView: Enhanced glass effects with `.ultraThinMaterial`, stronger translucency for background visibility
  - CheckForUpdatesView: Modernized No Updates Found card (centered layout, accent-colored icon), Previous Releases with tag icons and material background, increased rounded corners (28pt) throughout
  - GeneralView: Connection Preference uses segmented picker for modern look
  - CertificatesInfoView: Redesigned Validity & Timeline section with inset date cards, modernized Entitlements section with accent-colored icons, fixed "DAYS" → "Days" capitalization
  - CertificatesAddView: All SF symbols now use accent color instead of hardcoded colors
  - ServerView: Fixed Localhost Only SF symbol (was typo "extrernaldrive"), removed sparkles from SSL animation, cleaner success state
  - ConfigurationView: All SF symbols unified to use accent color
  - CreditsView: Full native SwiftUI ScrollView layout, grouped card design with rounded corners, modern spacing

- **Install Preview Sheet redesign (v2)**: Bottom-anchored App Store-style install modal:
  - Bottom sheet with slide-up spring animation, anchored above tab bar
  - Layered glass effect: `.ultraThinMaterial` outer sheet + `.regularMaterial` inner card
  - App size capsule (computed from archive/directory) replaces old age rating badge
  - `InstallSource` enum (`.source(name:)` / `.userImported`) for source display
  - Blue capsule Install button, "Installing..." progress with percentage, "Open" button on completion
  - All installation logic (server-based / IDeviceKitten) fully preserved

- **Widget Extension setup**: Created proper Widget Extension structure in `/FeatherWidgets/` directory:
  - Added `FeatherWidgets.swift` with proper `@main` entry point
  - Created `Info.plist` with widget extension configuration
  - Added App Groups entitlements for data sharing
  - Included comprehensive setup README at `/FeatherWidgets/README.md`
  - Updated main app entitlements with App Groups capability
  - Auto-updates widget data when certificates are added

- **LibraryView modernization**: Updated to a clean, minimal design without card-based UI or backgrounds. Features include:
  - Simple list layout with dividers
  - Large bold navigation title
  - Text-based filter buttons
  - Streamlined action buttons (text-only)
  - Clean empty state with subtle iconography

- **Live Activity UI redesign**: Modernized the Live Activity interface across three files:
  - `LiveActivityView.swift`: Redesigned with dynamic app name title, horizontal progress bar (vibrant green fill + muted track), "Step X/Y" indicator below the bar, bold percentage aligned right of the progress bar, bottom row with flashlight/camera circular buttons and notification indicator. All colors, fonts, and spacing driven dynamically from `LiveActivitySettings`.
  - `InstallationLiveActivityWidget.swift`: Updated lock screen view to match redesigned layout with same progress bar style, step indicator, percentage display, and bottom icon row. Dynamic Island views updated with settings-driven font design and bold percentage.
  - `LiveActivityManager.swift`: Verified data flow — all required fields (appName, progress, status, settings) are properly passed through to the UI layer. No changes needed.
  - Progress bar clamped to prevent overflow when progress > 1.0.

- **Bulk Source Import URL Scheme**: Added `portal://addBulkSource` scheme that accepts multiple `url` query parameters, validates each source by fetching its repository data, adds valid sources to storage, generates a Portal Transfer code, and presents results in a dedicated `SourcesAddBulkView` sheet with an accent-colored progress bar, success/error states, and copy-to-clipboard transfer code. Documented in URLSchemeView.

## Links
- [GitHub Repository](https://github.com/aoyn1xw/Portal)
- [Releases](https://github.com/aoyn1xw/Portal/releases)
- [Discord](https://wsfteam.xyz/discord)
