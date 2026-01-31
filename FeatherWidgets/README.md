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
   - **Product Name**: `FeatherWidgets`
   - **Team**: Select your development team
   - **Bundle Identifier**: `ayon1xw.Feather.FeatherWidgets` (or match your main app's bundle ID + `.FeatherWidgets`)
   - **Include Live Activity**: Uncheck (optional)
   - **Include Configuration App Intent**: Uncheck
5. Click **Finish**

### Step 2: Replace Generated Files

After Xcode creates the widget target:

1. Delete the auto-generated Swift files in the `FeatherWidgets` folder
2. Add these files from this directory to the `FeatherWidgets` target:
   - `FeatherWidgets.swift` (the main widget code with `@main`)
   - `Info.plist`
   - `FeatherWidgets.entitlements`
   - `Assets.xcassets` folder

### Step 3: Configure App Groups

Both the main app and widget extension need to share data via App Groups.

#### For the Main App (Feather target):
1. Select the **Feather** target in Xcode
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add **App Groups**
4. Add the group: `group.ayon1xw.Feather`

#### For the Widget Extension:
1. Select the **FeatherWidgets** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add **App Groups**
4. Add the same group: `group.ayon1xw.Feather`

### Step 4: Configure Build Settings

1. Select the **FeatherWidgets** target
2. Go to **Build Settings**
3. Set these values:
   - **iOS Deployment Target**: 16.0
   - **Code Signing Entitlements**: `FeatherWidgets/FeatherWidgets.entitlements`

### Step 5: Embed the Widget in the Main App

1. Select the **Feather** target
2. Go to **General > Frameworks, Libraries, and Embedded Content**
3. Click **+** and add `FeatherWidgetsExtension.appex`
4. Set **Embed** to "Embed & Sign"

### Step 6: Update URL Scheme Handling

Ensure your main app handles these URL schemes for widget deep links:
- `feather://add-source` - Opens the add source view
- `feather://add-certificate` - Opens the add certificate view  
- `feather://open-certificates` - Opens the certificates list

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
let userDefaults = UserDefaults(suiteName: "group.ayon1xw.Feather")
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

## Troubleshooting

### Widgets not appearing in widget gallery
- Ensure the widget extension is properly embedded in the main app
- Clean build folder (Cmd + Shift + K) and rebuild
- Delete the app from device and reinstall
- Check that `@main` is present in `FeatherWidgets.swift`

### Widget showing "No Certificate"
- Make sure App Groups are configured on both targets
- Verify the group identifier matches exactly: `group.ayon1xw.Feather`
- Call `Storage.shared.updateWidgetData()` when certificates change

### Widget not updating
- Call `WidgetCenter.shared.reloadAllTimelines()` after data changes
- Check that data is being written to the shared UserDefaults

## File Structure

```
FeatherWidgets/
├── FeatherWidgets.swift      # Main widget code with @main
├── Info.plist                # Extension Info.plist
├── FeatherWidgets.entitlements
├── Assets.xcassets/
│   ├── Contents.json
│   ├── AccentColor.colorset/
│   └── WidgetBackground.colorset/
└── README.md                 # This file
```
