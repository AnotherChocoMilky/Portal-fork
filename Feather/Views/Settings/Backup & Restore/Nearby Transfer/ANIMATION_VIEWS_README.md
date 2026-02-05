# Animation Views Documentation

## SenderAnimationView & ReceiverAnimationView

These are full-screen animation views designed to provide an AirDrop-like experience during Nearby Transfer operations in Portal.

---

## Features

### ✨ Visual Design
- **Full-screen immersive animations**
- **Modern gradient backgrounds** that change based on state
- **Smooth transitions** between different transfer states
- **Clean, minimal interface** focusing on the transfer process

### 🎨 Color Schemes
- **Sender**: Blue/Purple gradient (sending), Green/Teal (success), Red/Orange (failure)
- **Receiver**: Cyan/Indigo gradient (receiving), Green/Mint (success), Red/Pink (failure)

### 📱 iOS Compatibility
- **iOS 17+**: Advanced symbol effects (.pulse, .bounce, .symbolEffect)
- **iOS 16 and below**: Graceful fallback animations using standard SwiftUI animations
- All features work across supported iOS versions

---

## Animation States

### 1. Idle / Discovering / Connecting

**SenderAnimationView:**
- Pulsing concentric rings expanding outward
- Arrow.up.circle.fill icon in center
- Glowing effect around icon
- Status: "Finding Receiver..." / "Connecting..."

**ReceiverAnimationView:**
- Wave-like rings with gradient
- Arrow.down.circle.fill icon in center
- Pulsing glow effect
- Status: "Waiting for Sender..." / "Connecting..."

### 2. Transferring (Progress)

**Both Views:**
- Large circular progress indicator (200pt diameter)
- Percentage display in center (e.g., "65%")
- Animated upload/download icon
- Real-time information panel:
  - Bytes transferred / Total size
  - Current transfer speed (MB/s)
  - Estimated time remaining
- Smooth linear progress animation

### 3. Completed (Success)

**Both Views:**
- Complete circular ring animation
- Large checkmark icon
- "Sent Successfully!" / "Received Successfully!" message
- Particle effects bursting outward (iOS 17+)
- Celebratory spring animation
- Green/Teal or Green/Mint gradient background

### 4. Failed (Error)

**Both Views:**
- Partial circular ring
- Large X icon
- "Send Failed" / "Receive Failed" message
- Error description from TransferState
- Subtle shake/rotation animation
- Red gradient background

---

## Technical Implementation

### Dependencies
```swift
import SwiftUI
```

No external dependencies required - uses only SwiftUI standard library.

### State Management
Both views accept a `TransferState` enum parameter:
```swift
enum TransferState {
    case idle
    case discovering
    case connecting
    case transferring(progress: Double, bytesTransferred: Int64, totalBytes: Int64, speed: Double)
    case completed
    case failed(Error)
}
```

### Key Properties
- `@State private var isAnimating: Bool` - Controls animation triggers
- `@State private var pulseAnimation: Bool` - Ring pulse effect
- `@State private var scaleAmount: CGFloat` - Glow scaling
- `@State private var rotationAngle: Double` - Rotation effects (unused currently but available)

### Performance Considerations
- Animations are optimized to run smoothly at 60fps
- Uses SwiftUI's built-in animation system
- Minimal CPU usage with efficient view updates
- Progressive rendering based on state changes

---

## Integration Examples

### Option 1: Full-Screen Overlay
Display as an overlay on top of existing UI during active transfers:

```swift
ZStack {
    // Existing transfer UI
    PairingView()
    
    // Animation overlay
    if showAnimation {
        if mode == .send {
            SenderAnimationView(state: transferState)
        } else {
            ReceiverAnimationView(state: transferState)
        }
    }
}
```

### Option 2: Dedicated Screen
Navigate to a dedicated animation screen:

```swift
NavigationLink(destination: 
    mode == .send 
        ? SenderAnimationView(state: service.state)
        : ReceiverAnimationView(state: service.state)
) {
    Text("Start Transfer")
}
```

### Option 3: Modal Presentation
Present as a modal sheet:

```swift
.sheet(isPresented: $showTransfer) {
    if mode == .send {
        SenderAnimationView(state: service.state)
    } else {
        ReceiverAnimationView(state: service.state)
    }
}
```

### Option 4: Full-Screen Cover (Recommended)
Present as a full-screen cover for maximum immersion:

```swift
.fullScreenCover(isPresented: $showTransfer) {
    if mode == .send {
        SenderAnimationView(state: service.state)
    } else {
        ReceiverAnimationView(state: service.state)
    }
}
```

---

## Animation Details

### Timing Functions
- **Pulse Effect**: easeOut(duration: 2.0-2.5s) repeating
- **Glow Scale**: easeInOut(duration: 1.5-1.8s) autoreverses
- **Progress**: linear(duration: 0.3s) for smooth updates
- **Completion**: spring(response: 0.5-0.7s, damping: 0.6-0.7)
- **Failure**: easeInOut(duration: 0.1-0.12s) repeat 5-6 times

### Visual Hierarchy
1. Background gradient (full screen, safe area ignored)
2. Main animation circle (240x240pt for discovery, 200x200pt for progress)
3. Status text (28pt bold, 16pt subtitle)
4. Progress details panel (rounded rectangle with semi-transparent background)

### Accessibility
- Large, readable text with rounded design
- High contrast white text on colored backgrounds
- Clear status messages
- Progress information in multiple formats (percentage, bytes, time)

---

## Customization

Both views are designed to be self-contained and require minimal configuration. The visual design adapts automatically based on the `TransferState` provided.

### Color Customization
To customize colors, modify the `backgroundColors` computed property:

```swift
private var backgroundColors: [Color] {
    switch state {
    case .idle, .discovering, .connecting, .transferring:
        return [Color.customPrimary, Color.customSecondary]
    case .completed:
        return [Color.customSuccess, Color.customSuccessLight]
    case .failed:
        return [Color.customError, Color.customErrorLight]
    }
}
```

### Animation Speed
Adjust animation durations in the `startAnimations()` method.

---

## Best Practices

1. **Show during active transfers only** - Don't show animations during idle states
2. **Auto-dismiss on completion** - Consider dismissing automatically 2-3 seconds after success
3. **Handle failures gracefully** - Provide retry options when showing failed state
4. **Respect user interactions** - Allow users to cancel during transfer
5. **Test on real devices** - Ensure animations are smooth on target hardware

---

## Requirements

- **iOS 16.0+** (with fallbacks for iOS 17+ features)
- **SwiftUI framework**
- **NearbyTransferService** (for state management)

---

## File Locations

- `SenderAnimationView.swift`: `/Feather/Views/Settings/Backup & Restore/Nearby Transfer/`
- `ReceiverAnimationView.swift`: `/Feather/Views/Settings/Backup & Restore/Nearby Transfer/`
- Usage examples: `ANIMATION_VIEWS_USAGE.swift`

---

## Preview Support

Both views include SwiftUI preview providers for development:

```swift
#Preview {
    SenderAnimationView(state: .transferring(
        progress: 0.65, 
        bytesTransferred: 650000000, 
        totalBytes: 1000000000, 
        speed: 5242880
    ))
}
```

This allows viewing the animations in Xcode's preview canvas during development.

---

## Summary

These animation views provide a polished, professional transfer experience that rivals AirDrop's visual design. They handle all transfer states gracefully, provide real-time feedback, and maintain compatibility across iOS versions through carefully implemented fallbacks.
