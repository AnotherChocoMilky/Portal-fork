import SwiftUI
import PhotosUI

struct KeyboardCustomizationView: View {
    @StateObject private var manager = KeyboardCustomizeManager.shared

    @State private var startColor: Color = .blue
    @State private var endColor: Color = .cyan
    @State private var bgColor: Color = .black
    @State private var selectedItem: PhotosPickerItem?

    @FocusState private var isKeyboardFocused: Bool
    @State private var dummyText: String = ""
    @State private var showingAdvancedGradient = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: $manager.isEnabled) {
                    AppearanceRowLabel(icon: "keyboard", title: "Enable Backdrop", color: .purple)
                }
            } header: {
                AppearanceSectionHeader(title: "Status", icon: "power")
            } footer: {
                Text("When enabled, a custom dynamic background will appear behind the system keyboard. This works best with the system keyboard's natural translucency.")
            }

            if manager.isEnabled {
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        AppearanceRowLabel(icon: "photo.fill", title: "Custom Image", color: .green)
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                manager.backgroundImageData = data
                            }
                        }
                    }

                    if manager.backgroundImageData != nil {
                        Button(role: .destructive) {
                            manager.backgroundImageData = nil
                            selectedItem = nil
                        } label: {
                            AppearanceRowLabel(icon: "trash", title: "Remove Image", color: .red)
                        }
                    }
                } header: {
                    AppearanceSectionHeader(title: "Media", icon: "photo")
                }

                Section {
                    Toggle(isOn: $manager.showAnimatedOrbs) {
                        AppearanceRowLabel(icon: "sparkles", title: "Animated Orbs", color: .blue)
                    }

                    if manager.showAnimatedOrbs {
                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "circle.dotted", title: "Orb Count: \(manager.orbCount)", color: .blue)
                            Slider(value: Binding(get: { Double(manager.orbCount) }, set: { manager.orbCount = Int($0) }), in: 1...10, step: 1)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "bolt.fill", title: "Orb Speed: \(Int(manager.orbSpeed))", color: .yellow)
                            Slider(value: $manager.orbSpeed, in: 1...10)
                        }
                        .padding(.vertical, 4)
                    }

                    Toggle(isOn: $manager.useGradient) {
                        AppearanceRowLabel(icon: "paintpalette", title: "Custom Gradient", color: .orange)
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
                    } else {
                        ColorPicker(selection: $bgColor, supportsOpacity: false) {
                            AppearanceRowLabel(icon: "paintbrush.fill", title: "Background Color", color: .orange)
                        }
                        .onChange(of: bgColor) { manager.backgroundColor = $0.toHex() ?? "#1A1A1A" }
                    }
                } header: {
                    AppearanceSectionHeader(title: "Background Type", icon: "square.fill")
                }

                Section {
                    Toggle(isOn: $manager.isDynamicGradientEnabled) {
                        AppearanceRowLabel(icon: "sparkles.rectangle.stack", title: "Dynamic Gradient", color: .purple)
                    }

                    if manager.isDynamicGradientEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "timer", title: "Frequency: \(String(format: "%.1f", manager.dynamicGradientFrequency))", color: .blue)
                            Slider(value: $manager.dynamicGradientFrequency, in: 0.1...5.0, step: 0.1)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "slider.horizontal.3", title: "Amount: \(String(format: "%.1f", manager.dynamicGradientAmount))", color: .green)
                            Slider(value: $manager.dynamicGradientAmount, in: 0.1...10.0, step: 0.1)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "number", title: "Color Count: \(manager.dynamicGradientColorCount)", color: .orange)
                            Slider(value: Binding(get: { Double(manager.dynamicGradientColorCount) }, set: { manager.dynamicGradientColorCount = Int($0) }), in: 2...10, step: 1)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<manager.dynamicGradientColorCount, id: \.self) { index in
                                        ColorPicker("", selection: Binding(
                                            get: { Color(hex: manager.dynamicGradientColors[index]) },
                                            set: { manager.dynamicGradientColors[index] = $0.toHex() ?? "#FFFFFF" }
                                        ))
                                        .labelsHidden()
                                        .frame(width: 40, height: 40)
                                        .background(Color(hex: manager.dynamicGradientColors[index]))
                                        .clipShape(Circle())
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "waveform.path.ecg", title: "Pulse Intensity: \(String(format: "%.1f", manager.dynamicGradientPulseIntensity))", color: .red)
                            Slider(value: $manager.dynamicGradientPulseIntensity, in: 0.0...2.0, step: 0.1)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "arrow.up.right.circle", title: "Direction", color: .cyan)
                            HStack {
                                Spacer()
                                KeyboardDirectionPicker(direction: $manager.dynamicGradientDirection, color: .cyan)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)

                        Button {
                            showingAdvancedGradient = true
                        } label: {
                            AppearanceRowLabel(icon: "slider.horizontal.2.square", title: "Modify Advanced Controls", color: .purple)
                        }

                        Toggle(isOn: $manager.dynamicGradientShuffle) {
                            AppearanceRowLabel(icon: "shuffle", title: "Shuffle Colors", color: .indigo)
                        }

                        Picker(selection: $manager.dynamicGradientPreset) {
                            Text("Custom").tag(0)
                            Text("Aurora").tag(1)
                            Text("Sunset").tag(2)
                            Text("Ocean").tag(3)
                            Text("Nebula").tag(4)
                        } label: {
                            AppearanceRowLabel(icon: "wand.and.stars", title: "Preset", color: .pink)
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    AppearanceSectionHeader(title: "Dynamic Gradient", icon: "sparkles")
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
                    Button {
                        isKeyboardFocused = true
                    } label: {
                        AppearanceRowLabel(icon: "keyboard", title: "Open Keyboard", color: .blue)
                    }

                    TextField("Type here to test your backdrop...", text: $dummyText)
                        .focused($isKeyboardFocused)
                } header: {
                    AppearanceSectionHeader(title: "Test Backdrop", icon: "pencil")
                } footer: {
                    Text("Tap to open the keyboard and see your custom backdrop in action.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Keyboard Backdrop")
        .fullScreenCover(isPresented: $showingAdvancedGradient) {
            KeyboardDynamicGradientView()
        }
        .onAppear {
            startColor = Color(hex: manager.gradientStart)
            endColor = Color(hex: manager.gradientEnd)
            bgColor = Color(hex: manager.backgroundColor)
        }
    }
}
