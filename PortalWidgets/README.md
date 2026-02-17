# Portal Widget Extension Setup

This directory contains the Widget Extension for Portal. To make widgets appear on the iOS home screen, you must add this as a Widget Extension target in Xcode.

## Prerequisites

- Xcode 14.0 or later
- iOS 16.0+ deployment target
- An Apple Developer account (for App Groups capability)

## Setup Instructions

### Step 1: Add the Widget Extension Target

1. Open `Feather.xcodeproj` in Xcode
2. Go to **File > New > Target...**
3. Select **Widget Extension** under iOS
4. Configure the target:
   - **Product Name**: `PortalWidgets`
   - **Team**: Select your development team
   - **Bundle Identifier**: `ayon1xw.PortalDev.PortalWidgets`
   - **Include Live Activity**: Uncheck (optional)
   - **Include Configuration App Intent**: Uncheck
5. Click **Finish**

### Step 2: Replace Generated Files

After Xcode creates the widget target:

1. Delete the auto-generated Swift files in the `PortalWidgets` folder
2. Add these files from this directory to the `PortalWidgets` target:
   - `PortalWidgets.swift` (the main widget code with `@main`)
   - `Info.plist`
   - `PortalWidgets.entitlements`
   - `Assets.xcassets` folder

### Step 3: Configure App Groups

Both the main app and widget extension need to share data via App Groups.

#### For the Main App (Feather target):
1. Select the **Feather** target in Xcode
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add **App Groups**
4. Add the group: `group.ayon1xw.PortalDev`

#### For the Widget Extension:
1. Select the **PortalWidgets** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add **App Groups**
4. Add the same group: `group.ayon1xw.PortalDev`

### Step 4: Configure Build Settings

1. Select the **PortalWidgets** target
2. Go to **Build Settings**
3. Set these values:
   - **iOS Deployment Target**: 16.0
   - **Code Signing Entitlements**: `PortalWidgets/PortalWidgets.entitlements`

### Step 5: Enable Live Activities (Optional - iOS 16.2+)

Live Activities provide real-time installation progress in the Dynamic Island and Lock Screen.

1. Ensure `NSSupportsLiveActivities` is set to `YES` in the main app's `Info.plist` (already configured)
2. Add the `InstallationLiveActivityWidget.swift` file to the PortalWidgets target
3. The widget will automatically be included in the widget bundle

To enable/disable Live Activities at runtime:
- Go to Settings > Live Activity Settings in the app
- Toggle "Enable Live Activities"
- Configure appearance, colors, fonts, and animations
- Test using the "Force Show Live Activity" button

### Step 6: Embed the Widget in the Main App

1. Select the **Feather** target
2. Go to **General > Frameworks, Libraries, and Embedded Content**
3. Click **+** and add `PortalWidgets.appex`
4. Set **Embed** to "Embed & Sign"

### Step 7: Update URL Scheme Handling

Ensure your main app handles these URL schemes for widget deep links:
- `portal://add-source` - Opens the add source view
- `portal://add-certificate` - Opens the add certificate view
- `portal://open-certificates` - Opens the certificates list

Add URL scheme handling in your `FeatherApp.swift` or `SceneDelegate`:

```swift
.onOpenURL { url in
    switch url.host {
    case "add-source":
        // Navigate to add source
    case "add-certificate":
        // Navigate to add certificate
    case "open-certificates":
        // Navigate to certificates view
    default:
        break
    }
}
```

## Widget Data Sharing

The main app shares data with widgets via App Group UserDefaults:

```swift
let userDefaults = UserDefaults(suiteName: "group.ayon1xw.PortalDev")
userDefaults?.set(certName, forKey: "widget.selectedCertName")
userDefaults?.set(expiryDate.timeIntervalSince1970, forKey: "widget.selectedCertExpiry")
```

This is already implemented in `Storage+Certificate.swift` via the `updateWidgetData()` method.

## Available Widgets

### Quick Actions Widget
- **Sizes**: Small, Medium, Lock Screen (Circular, Rectangular)
- **Features**: Quick links to add sources, certificates, and check expiry

### Certificate Status Widget
- **Sizes**: Small, Lock Screen (Rectangular)
- **Features**: Shows certificate name and days until expiration

### Installation Live Activity Widget (iOS 16.2+)
- **Type**: Live Activity (Dynamic Island & Lock Screen)
- **Features**: 
  - Real-time installation progress tracking
  - Shows download, unzip, signing, and installation stages
  - Dynamic Island support with compact and expanded views
  - Customizable appearance (colors, fonts, animations)
  - Automatic updates during app installation
  - Speed and ETA calculations
- **Activation**: Automatically starts when downloading an app
- **Testing**: Use "Force Show Live Activity" button in Settings > Live Activity Settings

## File Structure

```
PortalWidgets/
├── PortalWidgets.swift                    # Main widget code with @main
├── InstallationLiveActivityWidget.swift   # Live Activity widget for installations
├── Info.plist                             # Extension Info.plist
├── PortalWidgets.entitlements
├── Assets.xcassets/
│   ├── Contents.json
│   ├── AccentColor.colorset/
│   └── WidgetBackground.colorset/
└── README.md                              # This file
```

### Widgets not appearing in widget gallery
- Ensure the widget extension is properly embedded in the main app
- Clean build folder (Cmd + Shift + K) and rebuild
- Delete the app from device and reinstall
- Check that `@main` is present in `PortalWidgets.swift`

### Widget showing "No Certificate"
- Make sure App Groups are configured on both targets
- Verify the group identifier matches exactly: `group.ayon1xw.PortalDev`
- Call `Storage.shared.updateWidgetData()` when certificates change

### Widget not updating
- Call `WidgetCenter.shared.reloadAllTimelines()` after data changes
- Check that data is being written to the shared UserDefaults

## File Structure

```
PortalWidgets/
├── PortalWidgets.swift      # Main widget code with @main
├── Info.plist                # Extension Info.plist
├── PortalWidgets.entitlements
├── Assets.xcassets/
│   ├── Contents.json
│   ├── AccentColor.colorset/
│   └── WidgetBackground.colorset/
└── README.md                 # This file
```
