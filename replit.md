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

## Links
- [GitHub Repository](https://github.com/aoyn1xw/Portal)
- [Releases](https://github.com/aoyn1xw/Portal/releases)
- [Discord](https://wsfteam.xyz/discord)
