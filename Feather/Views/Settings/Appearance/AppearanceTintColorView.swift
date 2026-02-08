import SwiftUI

// MARK: - View
struct AppearanceTintColorView: View {
	@AppStorage("Feather.userTintColor") private var selectedColorHex: String = "#0077BE"
	@AppStorage("Feather.userTintColorType") private var colorType: String = "solid"
	@AppStorage("Feather.userTintGradientStart") private var gradientStartHex: String = "#0077BE"
	@AppStorage("Feather.userTintGradientEnd") private var gradientEndHex: String = "#848ef9"
	
	@State private var isCustomSheetPresented = false
	
	private let tintOptions: [(name: String, hex: String)] = [
		("Ocean Blue", 		"#0077BE"),
		("Classic", 		"#848ef9"),
		("Berry",   		"#ff7a83"),
		("Cool Blue", 		"#4161F1"),
		("Fuchsia", 		"#FF00FF"),
		("Protokolle", 		"#4CD964"),
		("Aidoku", 			"#FF2D55"),
		("Clock", 			"#FF9500"),
		("Peculiar", 		"#4860e8"),
		("Very Peculiar", 	"#5394F7"),
		("Pink",			"#e18aab"),
		("Mint Fresh",		"#00E5C3"),
		("Sunset Orange",	"#FF6B35"),
		("Ocean Blue",		"#0077BE"),
		("Royal Purple",	"#7B2CBF"),
		("Forest Green",	"#2D6A4F"),
		("Ruby Red",		"#D62828"),
		("Golden Hour",		"#FFB703"),
		("Lavender",		"#9D4EDD"),
		("Coral",			"#FF006E"),
		("Teal Dream",		"#06FFF0"),
		("Crimson",			"#DC2F02"),
		("Sky Blue",		"#48CAE4"),
		("Emerald",			"#52B788"),
		("Hot Pink",		"#FF69B4"),
		("Lime Green",		"#32CD32"),
		("Indigo",			"#4B0082"),
		("Turquoise",		"#40E0D0"),
		("Peach",			"#FFDAB9"),
		("Magenta",			"#FF00FF"),
		("Amber",			"#FFBF00"),
		("Rose Gold",		"#B76E79"),
		("Cyan",			"#00FFFF"),
		("Salmon",			"#FA8072"),
		("Violet",			"#8B00FF"),
		("Gold",			"#FFD700"),
		("Bronze",			"#CD7F32"),
		("Silver",			"#C0C0C0"),
		("Navy",			"#001F3F"),
		("Maroon",			"#800000"),
		("Olive",			"#808000"),
		("Aqua",			"#00FFAA"),
		("Cherry",			"#DE3163"),
		("Mint",			"#98FF98"),
		("Plum",			"#DDA0DD"),
		// New color presets
		("Tangerine",		"#FFA500"),
		("Seafoam",			"#93E9BE"),
		("Periwinkle",		"#CCCCFF"),
		("Burgundy",		"#800020"),
		("Chartreuse",		"#7FFF00"),
		("Cobalt",			"#0047AB"),
		("Mauve",			"#E0B0FF"),
		("Scarlet",			"#FF2400"),
		("Slate",			"#708090"),
		("Jade",			"#00A86B"),
		("Raspberry",		"#E30B5D"),
		("Steel Blue",		"#4682B4"),
		("Orchid",			"#DA70D6"),
		("Sienna",			"#A0522D"),
		("Cerulean",		"#007BA7"),
		("Mustard",			"#FFDB58"),
		("Pine Green",		"#01796F"),
		("Apricot",			"#FBCEB1"),
		("Lilac",			"#C8A2C8"),
		("Mahogany",		"#C04000"),
		("Powder Blue",		"#B0E0E6"),
		("Vermillion",		"#E34234"),
		("Spring Green",	"#00FF7F"),
		("Blush",			"#DE5D83"),
		("Ochre",			"#CC7722"),
		("Periwinkle",		"#CCCCFF"),
		("Rust",			"#B7410E"),
		("Sage",			"#BCB88A"),
		("Brick Red",		"#CB4154"),
		("Mint Green",		"#98FF98")
	]

	@AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck")
	private var _ignoreSolariumLinkedOnCheck: Bool = false

	// MARK: Helper Methods
	private func updateTintColor() {
		if colorType == "gradient" {
			let startColor: SwiftUI.Color = SwiftUI.Color(hex: gradientStartHex)
			UIApplication.topViewController()?.view.window?.tintColor = UIColor(startColor)
		} else {
			UIApplication.topViewController()?.view.window?.tintColor = UIColor(SwiftUI.Color(hex: selectedColorHex))
		}
	}

	// MARK: Body
	var body: some View {
		Button {
			isCustomSheetPresented = true
		} label: {
			HStack(spacing: 12) {
				ZStack {
					if colorType == "gradient" {
						LinearGradient(
							colors: [SwiftUI.Color(hex: gradientStartHex), SwiftUI.Color(hex: gradientEndHex)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
						.frame(width: 24, height: 24)
						.clipShape(Circle())
					} else {
						Circle()
							.fill(SwiftUI.Color(hex: selectedColorHex))
							.frame(width: 24, height: 24)
					}
					Circle()
						.strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
						.frame(width: 24, height: 24)
				}
				
				Text("Theme Color")
					.foregroundStyle(.primary)

				Spacer()

				Text(colorName)
					.font(.subheadline)
					.foregroundStyle(.secondary)

				Image(systemName: "chevron.right")
					.font(.caption.weight(.semibold))
					.foregroundStyle(.quaternary)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
			.background(Color(uiColor: .secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
		}
		.buttonStyle(.plain)
		.sheet(isPresented: $isCustomSheetPresented) {
			ThemeColorPickerSheet(
				selectedColorHex: $selectedColorHex,
				colorType: $colorType,
				gradientStartHex: $gradientStartHex,
				gradientEndHex: $gradientEndHex,
				tintOptions: tintOptions
			)
			.presentationDetents([.medium, .large])
			.presentationDragIndicator(.visible)
		}
	}

	private var colorName: String {
		if colorType == "gradient" {
			return "Gradient"
		}
		return tintOptions.first(where: { $0.hex == selectedColorHex })?.name ?? "Custom"
	}
}

struct ThemeColorPickerSheet: View {
	@Environment(\.dismiss) var dismiss
	@Binding var selectedColorHex: String
	@Binding var colorType: String
	@Binding var gradientStartHex: String
	@Binding var gradientEndHex: String
	let tintOptions: [(name: String, hex: String)]

	@State private var showCustomPicker = false

	var body: some View {
		NavigationView {
			ScrollView {
				VStack(alignment: .leading, spacing: 20) {
					Text("Select a color to personalize your experience.")
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.padding(.horizontal)

					LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
						// Custom / Advanced button
						VStack(spacing: 8) {
							ZStack {
								Circle()
									.fill(LinearGradient(colors: [.blue, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
									.frame(width: 44, height: 44)

								Image(systemName: "plus")
									.font(.title3.weight(.bold))
									.foregroundStyle(.white)
							}

							Text("Advanced")
								.font(.caption.weight(.medium))
						}
						.frame(height: 90)
						.frame(maxWidth: .infinity)
						.background(Color(uiColor: .tertiarySystemGroupedBackground))
						.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
						.onTapGesture {
							showCustomPicker = true
						}

						ForEach(tintOptions, id: \.hex) { option in
							let color = SwiftUI.Color(hex: option.hex)
							VStack(spacing: 8) {
								Circle()
									.fill(color)
									.frame(width: 44, height: 44)
									.overlay(
										Circle()
											.strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
									)
									.overlay {
										if selectedColorHex == option.hex && colorType == "solid" {
											Image(systemName: "checkmark")
												.font(.caption.weight(.bold))
												.foregroundStyle(.white)
												.shadow(radius: 2)
										}
									}

								Text(option.name)
									.font(.caption.weight(.medium))
									.lineLimit(1)
							}
							.frame(height: 90)
							.frame(maxWidth: .infinity)
							.background(Color(uiColor: .tertiarySystemGroupedBackground))
							.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
							.overlay(
								RoundedRectangle(cornerRadius: 16, style: .continuous)
									.strokeBorder(selectedColorHex == option.hex && colorType == "solid" ? color : .clear, lineWidth: 2)
							)
							.onTapGesture {
								colorType = "solid"
								selectedColorHex = option.hex
								HapticsManager.shared.softImpact()
							}
						}
					}
					.padding(.horizontal)
				}
				.padding(.vertical)
			}
			.navigationTitle("Theme Colors")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") { dismiss() }
						.fontWeight(.semibold)
				}
			}
			.sheet(isPresented: $showCustomPicker) {
				CustomColorPickerView(
					colorType: $colorType,
					selectedColorHex: $selectedColorHex,
					gradientStartHex: $gradientStartHex,
					gradientEndHex: $gradientEndHex
				)
			}
		}
	}
}

// MARK: - Custom Color Picker View
struct CustomColorPickerView: View {
	@Environment(\.dismiss) var dismiss
	@Binding var colorType: String
	@Binding var selectedColorHex: String
	@Binding var gradientStartHex: String
	@Binding var gradientEndHex: String

	@State private var solidColor: Color = .accentColor
	@State private var gradientStart: Color = .purple
	@State private var gradientEnd: Color = .blue

	// Gradient Presets
	private let gradientPresets: [(name: String, start: String, end: String)] = [
		("Sunset", "#FF6B35", "#F7931E"),
		("Ocean", "#00B4DB", "#0083B0"),
		("Purple Dream", "#B490CA", "#5E4FA2"),
		("Forest", "#2D6A4F", "#52B788"),
		("Fire", "#FF0844", "#FFB199"),
		("Cotton Candy", "#FFC0CB", "#FFE5B4"),
		("Northern Lights", "#00FFA3", "#03E1FF"),
		("Twilight", "#4E54C8", "#8F94FB"),
		("Peachy", "#ED4264", "#FFEDBC"),
		("Cool Breeze", "#2BC0E4", "#EAECC6"),
		("Royal", "#141E30", "#243B55"),
		("Emerald", "#348F50", "#56B4D3")
	]

	var body: some View {
		NavigationView {
			Form {
				Section {
					Picker("Type", selection: $colorType) {
						Text("Solid Color").tag("solid")
						Text("Gradient").tag("gradient")
					}
					.pickerStyle(.segmented)
				}

				if colorType == "solid" {
					Section(header: Text("Solid Color")) {
						ColorPicker("Color", selection: $solidColor, supportsOpacity: false)
					}
				} else {
					Section(header: Text("Custom Gradient")) {
						ColorPicker("Start Color", selection: $gradientStart, supportsOpacity: false)
						ColorPicker("End Color", selection: $gradientEnd, supportsOpacity: false)
					}

					Section(header: Text("Gradient Presets")) {
						ScrollView(.horizontal, showsIndicators: false) {
							HStack(spacing: 16) {
								ForEach(gradientPresets, id: \.name) { preset in
									VStack(spacing: 8) {
										Circle()
											.fill(
												LinearGradient(
													colors: [SwiftUI.Color(hex: preset.start), SwiftUI.Color(hex: preset.end)],
													startPoint: .topLeading,
													endPoint: .bottomTrailing
												)
											)
											.frame(width: 60, height: 60)
											.overlay(
												Circle()
													.stroke(
														gradientStartHex == preset.start && gradientEndHex == preset.end
															? Color.accentColor
															: Color.clear,
														lineWidth: 3
													)
											)
											.onTapGesture {
												gradientStart = SwiftUI.Color(hex: preset.start)
												gradientEnd = SwiftUI.Color(hex: preset.end)
											}

										Text(preset.name)
											.font(.caption2)
											.foregroundStyle(.secondary)
											.lineLimit(1)
									}
									.frame(width: 80)
								}
							}
							.padding(.vertical, 8)
						}
						.listRowInsets(EdgeInsets())
					}
				}

				Section(header: Text("Preview")) {
					HStack {
						Spacer()
						if colorType == "solid" {
							Circle()
								.fill(solidColor)
								.frame(width: 100, height: 100)
								.shadow(color: solidColor.opacity(0.4), radius: 10, x: 0, y: 5)
						} else {
							Circle()
								.fill(
									LinearGradient(
										colors: [gradientStart, gradientEnd],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 100, height: 100)
								.shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
						}
						Spacer()
					}
					.padding()
				}
			}
			.navigationTitle("Custom Color")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar(content: {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") {
						if colorType == "solid" {
							selectedColorHex = solidColor.toHex() ?? "#0077BE"
							UIApplication.topViewController()?.view.window?.tintColor = UIColor(solidColor)
						} else {
							gradientStartHex = gradientStart.toHex() ?? "#0077BE"
							gradientEndHex = gradientEnd.toHex() ?? "#848ef9"
						}
						dismiss()
					}
				}
			})
		}
		.presentationDetents([.large])
		.onAppear {
			solidColor = SwiftUI.Color(hex: selectedColorHex)
			gradientStart = SwiftUI.Color(hex: gradientStartHex)
			gradientEnd = SwiftUI.Color(hex: gradientEndHex)
		}
	}
}
}
