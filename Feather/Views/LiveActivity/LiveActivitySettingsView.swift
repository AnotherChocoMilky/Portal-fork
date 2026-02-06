import SwiftUI
import NimbleViews
import ActivityKit

/// Settings view for customizing Live Activity appearance and behavior
struct LiveActivitySettingsView: View {
    @AppStorage("Feather.liveActivityEnabled") private var liveActivityEnabled: Bool = true
    
    // Live Activity settings managed by LiveActivityManager
    @State private var settings: LiveActivitySettings = LiveActivitySettings.default
    @State private var showColorPicker = false
    @State private var isShowingMockActivity = false
    
    var body: some View {
        NBNavigationView("Live Activity Settings") {
            List {
                enabledSection
                appearanceSection
                progressSection
                detailsSection
                testingSection
                infoSection
            }
            .listStyle(.insetGrouped)
        }
        .onAppear {
            loadSettings()
        }
    }
    
    // MARK: - Load/Save Settings
    
    private func loadSettings() {
        if #available(iOS 16.2, *) {
            settings = LiveActivityManager.shared.loadSettings()
        }
    }
    
    private func saveSettings() {
        if #available(iOS 16.2, *) {
            LiveActivityManager.shared.saveSettings(settings)
        }
    }
    
    // MARK: - Sections
    
    private var enabledSection: some View {
        Section {
            Toggle(isOn: $liveActivityEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(liveActivityEnabled ? .green : .gray)
                        .frame(width: 28, height: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Live Activities")
                            .font(.body)
                        
                        Text("Show installation progress in Dynamic Island and Lock Screen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Status")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            if #available(iOS 16.2, *) {
                Text("Live Activities require iOS 16.2 or later for Dynamic Island support.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Live Activities are not available on this iOS version. Requires iOS 16.2+")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private var appearanceSection: some View {
        Section {
            // Background Texture
            Picker(selection: $settings.backgroundTexture) {
                ForEach(LiveActivitySettings.BackgroundTexture.allCases, id: \.self) { texture in
                    Text(texture.rawValue).tag(texture)
                }
            } label: {
                Label("Background", systemImage: "square.3.layers.3d")
            }
            .onChange(of: settings.backgroundTexture) { _ in saveSettings() }
            
            // Font Family
            Picker(selection: $settings.fontFamily) {
                ForEach(LiveActivitySettings.FontFamily.allCases, id: \.self) { family in
                    Text(family.rawValue).tag(family)
                }
            } label: {
                Label("Font", systemImage: "textformat")
            }
            .onChange(of: settings.fontFamily) { _ in saveSettings() }
            
            // Font Weight
            Picker(selection: $settings.fontWeight) {
                ForEach(LiveActivitySettings.FontWeightOption.allCases, id: \.self) { weight in
                    Text(weight.rawValue).tag(weight)
                }
            } label: {
                Label("Font Weight", systemImage: "bold")
            }
            .onChange(of: settings.fontWeight) { _ in saveSettings() }
            
            // Improved Accent Color UI
            VStack(alignment: .leading, spacing: 12) {
                Label("Accent Color", systemImage: "paintpalette.fill")
                    .font(.body)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 35))], spacing: 12) {
                    let colors: [Color] = [.blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .cyan, .indigo, .gray]

                    ForEach(colors, id: \.self) { color in
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .onTapGesture {
                                    settings.accentColor = CodableColor(color: color)
                                    saveSettings()
                                    HapticsManager.shared.light()
                                }

                            if isSameColor(settings.accentColor.color, color) {
                                Circle()
                                    .stroke(Color.primary, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }
                        }
                        .frame(width: 40, height: 40)
                    }

                    // Custom Color Picker Button
                    Button {
                        showColorPicker = true
                        HapticsManager.shared.light()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(AngularGradient(colors: [.red, .yellow, .green, .blue, .purple, .red], center: .center))
                                .frame(width: 30, height: 30)

                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Appearance")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            Text("Customize the visual style of Live Activities")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerView(selectedColor: $settings.accentColor, onDismiss: saveSettings)
        }
    }
    
    private func isSameColor(_ color1: Color, _ color2: Color) -> Bool {
        // Simple comparison for predefined colors
        color1 == color2
    }

    private var progressSection: some View {
        Section {
            // Progress Bar Style
            Picker(selection: $settings.progressBarStyle) {
                ForEach(LiveActivitySettings.ProgressBarStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            } label: {
                Label("Progress Style", systemImage: "progressbar.fill")
            }
            .onChange(of: settings.progressBarStyle) { _ in saveSettings() }
            
            // Icon Size
            Picker(selection: $settings.iconSize) {
                ForEach(LiveActivitySettings.IconSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            } label: {
                Label("Icon Size", systemImage: "app.dashed")
            }
            .onChange(of: settings.iconSize) { _ in saveSettings() }
            
            // Animation Style
            Picker(selection: $settings.animationStyle) {
                ForEach(LiveActivitySettings.AnimationStyle.allCases, id: \.self) { animation in
                    Text(animation.rawValue).tag(animation)
                }
            } label: {
                Label("Animation", systemImage: "wand.and.stars")
            }
            .onChange(of: settings.animationStyle) { _ in saveSettings() }

            // New Customization Toggles
            Toggle(isOn: $settings.showEstimatedTime) {
                Label("Show Estimated Time", systemImage: "clock.fill")
            }
            .onChange(of: settings.showEstimatedTime) { _ in saveSettings() }

            Toggle(isOn: $settings.highFrequencyUpdates) {
                Label("High Frequency Updates", systemImage: "bolt.horizontal.fill")
            }
            .onChange(of: settings.highFrequencyUpdates) { _ in saveSettings() }

        } header: {
            Text("Progress Display")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            Text("Configure how progress is displayed and updated.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var detailsSection: some View {
        Section {
            // Detail Density
            Picker(selection: $settings.detailDensity) {
                ForEach(LiveActivitySettings.DetailDensity.allCases, id: \.self) { density in
                    Text(density.rawValue).tag(density)
                }
            } label: {
                Label("Detail Level", systemImage: "list.bullet.indent")
            }
            .onChange(of: settings.detailDensity) { _ in saveSettings() }
        } header: {
            Text("Details")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            Text("Control how much information is shown")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var testingSection: some View {
        Section {
            if #available(iOS 16.2, *) {
                Button {
                    HapticsManager.shared.light()
                    isShowingMockActivity = true
                    LiveActivityManager.shared.startMockActivity()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.purple)
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Force Show Live Activity")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text("Test with mock installation data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if isShowingMockActivity {
                            ProgressView()
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .disabled(isShowingMockActivity)
            } else {
                Text("Testing requires iOS 16.2+")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Testing")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            Text("Test your Live Activity settings with a mock installation. The activity will automatically complete after a few seconds.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onChange(of: isShowingMockActivity) { newValue in
            if newValue {
                // Reset after 12 seconds (mock takes ~11 seconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                    isShowingMockActivity = false
                }
            }
        }
    }
    
    private var infoSection: some View {
        Section {
            LiveActivityInfoRow(
                icon: "iphone",
                title: "Dynamic Island",
                description: "On iPhone 14 Pro and later, Live Activities appear in the Dynamic Island"
            )
            
            LiveActivityInfoRow(
                icon: "lock.fill",
                title: "Lock Screen",
                description: "Live Activities also appear on the Lock Screen for all supported devices"
            )
            
            LiveActivityInfoRow(
                icon: "app.badge.fill",
                title: "Background Updates",
                description: "Live Activities can be updated even when Portal is in the background"
            )
        } header: {
            Text("About Live Activities")
                .font(.system(size: 11, weight: .semibold))
        }
    }
}

// MARK: - Color Picker View

struct ColorPickerView: View {
    @Binding var selectedColor: CodableColor
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var color: Color
    
    init(selectedColor: Binding<CodableColor>, onDismiss: @escaping () -> Void) {
        self._selectedColor = selectedColor
        self.onDismiss = onDismiss
        self._color = State(initialValue: selectedColor.wrappedValue.color)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ColorPicker("Select Accent Color", selection: $color, supportsOpacity: false)
                    .padding()
                
                Text("Preview")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Circle()
                        .fill(color)
                        .frame(width: 50, height: 50)
                    
                    VStack(alignment: .leading) {
                        Text("Sample Text")
                            .foregroundColor(color)
                            .font(.headline)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(height: 6)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Accent Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Convert Color to CodableColor (approximation)
                        selectedColor = CodableColor(color: color)
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct LiveActivityInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    LiveActivitySettingsView()
}
