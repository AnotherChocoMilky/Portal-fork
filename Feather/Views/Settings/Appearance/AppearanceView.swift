import SwiftUI
import NimbleViews
import UIKit

// MARK: - Appearance View
struct AppearanceView: View {
    @AppStorage("Feather.userInterfaceStyle") private var userInterfaceStyle: Int = UIUserInterfaceStyle.unspecified.rawValue
    @AppStorage(UserDefaults.Keys.installTrigger) private var installTrigger: Int = 0 // 0: Manual, 1: Automatic
    @AppStorage("Feather.shouldTintIcons") private var _shouldTintIcons: Bool = false
    @AppStorage("Feather.storeCellAppearance") private var storeCellAppearance: Int = 0
    @AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck") private var ignoreSolariumLinkedOnCheck: Bool = false
    @AppStorage("Feather.showNews") private var showNews: Bool = true
    @AppStorage("Feather.showIconsInAppearance") private var showIconsInAppearance: Bool = true
    @AppStorage("Feather.useNewAllAppsView") private var useNewAllAppsView: Bool = true
    @AppStorage("Feather.greetingsName") private var greetingsName: String = ""
    @StateObject private var hapticsManager = HapticsManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Theme
                appearanceCard(title: "Theme", icon: "paintbrush.fill", onIconLongPress: {
                    let icons = ["AppIcon", "AppIcon-1", "AppIcon-2", "AppIcon-3"]
                    let current = UIApplication.shared.alternateIconName ?? "AppIcon"
                    let next = icons[(icons.firstIndex(of: current) ?? 0 + 1) % icons.count]
                    UIApplication.shared.setAlternateIconName(next == "AppIcon" ? nil : next)
                    ToastManager.shared.show("🎭 Icon Cycle: \(next)", type: .success)
                    HapticsManager.shared.success()
                }) {
                    Picker("Appearance", selection: $userInterfaceStyle) {
                        ForEach(UIUserInterfaceStyle.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { style in
                            Label(style.label, systemImage: style.iconName).tag(style.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(16)
                }

                // MARK: - Color
                appearanceCard(title: "Color", icon: "paintpalette.fill") {
                    AppearanceNavRow(icon: "paintpalette.fill", title: "Customization", color: .pink, destination: ColorCustomizationView())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                // MARK: - Tint Icons
                if #available(iOS 18.0, *) {
                    appearanceCard(title: "Tint Icons", icon: "paintpalette", footer: "Allow Portal to tint your app icons when signing apps with the current accent color set.") {
                        AppearanceToggle(icon: "paintpalette", title: "Tint App Icons", isOn: $_shouldTintIcons, color: .pink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                }

                // MARK: - Display
                appearanceCard(title: "Display", icon: "eye.fill") {
                    VStack(spacing: 0) {
                        AppearanceToggle(icon: "square.grid.2x2", title: "Show Icons", isOn: $showIconsInAppearance, color: .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        Divider().padding(.leading, 52)
                        AppearanceToggle(icon: "rectangle.grid.1x2", title: "New Apps View", isOn: $useNewAllAppsView, color: .purple)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        Divider().padding(.leading, 52)
                        AppearanceToggle(icon: "newspaper", title: "Show News", isOn: $showNews, color: .orange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                }

                // MARK: - Haptics
                appearanceCard(title: "App Haptics", icon: "waveform") {
                    VStack(spacing: 0) {
                        Toggle(isOn: $hapticsManager.isEnabled) {
                            AppearanceRowLabel(icon: "iphone.radiowaves.left.and.right", title: "Enable Haptics", color: .purple)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .onChange(of: hapticsManager.isEnabled) { newValue in
                            if newValue { HapticsManager.shared.impact() }
                        }

                        if hapticsManager.isEnabled {
                            Divider().padding(.leading, 52)
                            ForEach(HapticsManager.HapticIntensity.allCases, id: \.self) { intensity in
                                HapticIntensityRow(
                                    intensity: intensity,
                                    isSelected: hapticsManager.intensity == intensity
                                ) {
                                    hapticsManager.intensity = intensity
                                    HapticsManager.shared.impact()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                if intensity != HapticsManager.HapticIntensity.allCases.last {
                                    Divider().padding(.leading, 52)
                                }
                            }
                        }
                    }
                }

                // MARK: - Personalization
                appearanceCard(title: "Personalization", icon: "person.crop.circle.fill", footer: "Personalize the Home Screen greeting.") {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.green)
                            .frame(width: 24)

                        Text("Your Name")
                            .font(.body)

                        Spacer()

                        TextField("Enter Name", text: $greetingsName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                // MARK: - Customization
                appearanceCard(title: "Customization", icon: "slider.horizontal.3") {
                    VStack(spacing: 0) {
                        AppearanceNavRow(icon: "eye.slash.fill", title: "Hide UI Elements", color: .red, destination: AppHideElementsView())
                        Divider().padding(.leading, 52)
                        AppearanceNavRow(icon: "rectangle.stack.fill", title: "All Apps", color: .blue, destination: AllAppsCustomizationView())
                        Divider().padding(.leading, 52)
                        AppearanceNavRow(icon: "rectangle.topthird.inset.filled", title: "Status Bar", color: .cyan, destination: StatusBarCustomizationView())
                        Divider().padding(.leading, 52)
                        AppearanceNavRow(icon: "dock.rectangle", title: "Tab Bar", color: .indigo, destination: TabBarCustomizationView())

                        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 16 {
                            Divider().padding(.leading, 52)
                            AppearanceNavRow(icon: "keyboard", title: "Keyboard Backdrop", color: .purple, destination: KeyboardCustomizationView())
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Experiments
                if #available(iOS 19.0, *) {
                    appearanceCard(title: "Liquid Glass", icon: "sparkle", footer: "Requires Portal to restart so Liquid Glass can be applied.") {
                        AppearanceToggle(icon: "sparkles", title: "Enable Liquid Glass", isOn: $ignoreSolariumLinkedOnCheck, color: .pink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: userInterfaceStyle) { value in
            if let style = UIUserInterfaceStyle(rawValue: value) {
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .forEach { $0.overrideUserInterfaceStyle = style }
            }
        }
        .onChange(of: ignoreSolariumLinkedOnCheck) { _ in
            UIApplication.shared.suspendAndReopen()
        }
    }
    
    // MARK: - Helper Views
    
    private func appearanceCard<Content: View>(title: String, icon: String, footer: String? = nil, onIconLongPress: (() -> Void)? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AppearanceSectionHeader(title: title, icon: icon)
                .padding(.leading, 8)
                .onLongPressGesture {
                    onIconLongPress?()
                }
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)

            if let footer = footer {
                Text(footer)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 2)
            }
        }
    }
}

// MARK: - Appearance Components

struct AppearanceSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

struct AppearanceRowLabel: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(.body, design: .rounded))
        }
    }
}

struct AppearanceToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        Toggle(isOn: $isOn) {
            AppearanceRowLabel(icon: icon, title: title, color: color)
        }
    }
}

struct AppearanceNavRow<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                AppearanceRowLabel(icon: icon, title: title, color: color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

private struct HapticIntensityRow: View {
    let intensity: HapticsManager.HapticIntensity
    let isSelected: Bool
    let action: () -> Void
    
    private var icon: String {
        switch intensity {
        case .slow, .defaultIntensity: return "waveform.path.ecg"
        case .hard, .extreme: return "waveform.path.ecg.rectangle"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 24)
                Text(intensity.title)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.medium)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
