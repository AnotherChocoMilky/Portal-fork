import SwiftUI
import PhotosUI

struct KeyboardCustomizationView: View {
    @StateObject private var manager = KeyboardCustomizeManager.shared
    @State private var selectedItem: PhotosPickerItem?

    @State private var startColor: Color = .blue
    @State private var endColor: Color = .cyan

    var body: some View {
        List {
            Section {
                Toggle(isOn: $manager.isEnabled) {
                    AppearanceRowLabel(icon: "keyboard", title: "Enable Backdrop", color: .purple)
                }
            } header: {
                AppearanceSectionHeader(title: "Status", icon: "power")
            } footer: {
                Text("When enabled, a custom background will appear behind the system keyboard. This works best with the system keyboard's natural translucency.")
            }

            if manager.isEnabled {
                Section {
                    Toggle(isOn: Binding(
                        get: { manager.useImage },
                        set: { if $0 { manager.useImage = true; manager.useGradient = false } else { manager.useImage = false } }
                    )) {
                        AppearanceRowLabel(icon: "photo", title: "Use Image", color: .blue)
                    }

                    if manager.useImage {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack {
                                AppearanceRowLabel(icon: "photo.stack", title: "Select Image", color: .blue)
                                Spacer()
                                if let image = manager.cachedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Text("None")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    manager.saveImage(image)
                                }
                            }
                        }
                    }

                    Toggle(isOn: Binding(
                        get: { manager.useGradient },
                        set: { if $0 { manager.useGradient = true; manager.useImage = false } else { manager.useGradient = false } }
                    )) {
                        AppearanceRowLabel(icon: "paintpalette", title: "Use Gradient", color: .orange)
                    }

                    if manager.useGradient {
                        ColorPicker(selection: $startColor, supportsOpacity: false) {
                            AppearanceRowLabel(icon: "1.circle", title: "Start Color", color: .orange)
                        }
                        .onChange(of: startColor) { manager.gradientStart = $0.toHex() ?? "#0077BE" }

                        ColorPicker(selection: $endColor, supportsOpacity: false) {
                            AppearanceRowLabel(icon: "2.circle", title: "End Color", color: .orange)
                        }
                        .onChange(of: endColor) { manager.gradientEnd = $0.toHex() ?? "#00AEEF" }
                    }
                } header: {
                    AppearanceSectionHeader(title: "Background Type", icon: "square.fill")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "drop", title: "Opacity: \(Int(manager.opacity * 100))%", color: .blue)
                        Slider(value: $manager.opacity, in: 0...1)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "fossil.shell", title: "Blur: \(Int(manager.blurRadius))", color: .cyan)
                        Slider(value: $manager.blurRadius, in: 0...30)
                    }
                    .padding(.vertical, 4)
                } header: {
                    AppearanceSectionHeader(title: "Effects", icon: "wand.and.stars")
                }

                Section {
                    KeyboardBackdropView()
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            Text("Preview")
                                .font(.caption.bold())
                                .padding(4)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(8),
                            alignment: .topLeading
                        )
                } header: {
                    AppearanceSectionHeader(title: "Preview", icon: "eye")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Keyboard Backdrop")
        .onAppear {
            startColor = Color(hex: manager.gradientStart)
            endColor = Color(hex: manager.gradientEnd)
        }
    }
}

struct KeyboardBackdropView: View {
    @ObservedObject var manager = KeyboardCustomizeManager.shared

    var body: some View {
        ZStack {
            if manager.useImage, let image = manager.cachedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if manager.useGradient {
                LinearGradient(
                    colors: [Color(hex: manager.gradientStart), Color(hex: manager.gradientEnd)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color(uiColor: .systemBackground)
            }
        }
        .blur(radius: manager.blurRadius)
        .opacity(manager.opacity)
    }
}

struct KeyboardBackdropModifier: ViewModifier {
    @ObservedObject var manager = KeyboardCustomizeManager.shared

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if manager.isEnabled && manager.keyboardHeight > 0 {
                KeyboardBackdropView()
                    .frame(maxWidth: .infinity)
                    .frame(height: manager.keyboardHeight)
                    .transition(.move(edge: .bottom))
                    .ignoresSafeArea(.container, edges: .bottom)
                    .zIndex(999)
            }
        }
    }
}

extension View {
    func withKeyboardBackdrop() -> some View {
        self.modifier(KeyboardBackdropModifier())
    }
}
