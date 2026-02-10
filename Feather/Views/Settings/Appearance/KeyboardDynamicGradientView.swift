import SwiftUI

struct KeyboardDynamicGradientView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager = KeyboardCustomizeManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // Background Preview
                KeyboardBackdropView(manager: manager)
                    .ignoresSafeArea()
                    .opacity(0.4)

                ScrollView {
                    VStack(spacing: 24) {
                        // Live Preview Card
                        VStack {
                            KeyboardBackdropView(manager: manager)
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: .black.opacity(0.3), radius: 20)
                                .padding()

                            Text("Live Preview")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 20) {
                            // Primary Controls
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Movement & Animation")
                                    .font(.headline)

                                controlRow(title: "Frequency", value: $manager.dynamicGradientFrequency, range: 0.1...5.0, icon: "timer")
                                controlRow(title: "Amount", value: $manager.dynamicGradientAmount, range: 0.1...10.0, icon: "slider.horizontal.3")
                                controlRow(title: "Pulse", value: $manager.dynamicGradientPulseIntensity, range: 0.0...2.0, icon: "waveform.path.ecg")
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            // Direction Control
                            VStack(spacing: 15) {
                                Text("Gradient Direction")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                KeyboardDirectionPicker(direction: $manager.dynamicGradientDirection, color: .purple)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            // Color Selection
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("Colors (\(manager.dynamicGradientColorCount))")
                                        .font(.headline)
                                    Spacer()
                                    Stepper("", value: Binding(get: { manager.dynamicGradientColorCount }, set: { manager.dynamicGradientColorCount = $0 }), in: 2...10)
                                }

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
                                    ForEach(0..<manager.dynamicGradientColorCount, id: \.self) { index in
                                        colorPickerCircle(index: index)
                                    }
                                }

                                Toggle("Shuffle Colors", isOn: $manager.dynamicGradientShuffle)
                                    .padding(.top, 8)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Dynamic Gradient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    @ViewBuilder
    private func controlRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Text(String(format: "%.1f", value.wrappedValue))
                    .font(.caption.monospacedDigit())
            }
            Slider(value: value, in: range)
        }
    }

    @ViewBuilder
    private func colorPickerCircle(index: Int) -> some View {
        let hex = index < manager.dynamicGradientColors.count ? manager.dynamicGradientColors[index] : "#FFFFFF"
        VStack {
            ColorPicker("", selection: Binding(
                get: { Color(hex: hex) },
                set: { newColor in
                    if index < manager.dynamicGradientColors.count {
                        manager.dynamicGradientColors[index] = newColor.toHex() ?? "#FFFFFF"
                    }
                }
            ))
            .labelsHidden()
            .frame(width: 44, height: 44)
            .background(Color(hex: hex))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))

            Text("\(index + 1)")
                .font(.caption2)
        }
    }
}
