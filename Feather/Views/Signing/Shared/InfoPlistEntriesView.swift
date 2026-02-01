import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

// MARK: - Info.plist Entries View
struct InfoPlistEntriesView: View {
	@Environment(\.dismiss) var dismiss
	@Binding var options: Options
	
	@State private var editingKey: String?
	@State private var showAddEntryDialog = false
	@State private var showImportSheet = false
	@State private var newKey = ""
	@State private var newValueType: InfoPlistValueType = .string
	@State private var newStringValue = ""
	@State private var newBoolValue = false
	@State private var newNumberValue = ""
	@State private var showPresetSheet = false
	
	enum InfoPlistValueType: String, CaseIterable {
		case string = "String"
		case boolean = "Boolean"
		case number = "Number"
		case array = "Array"
		
		var icon: String {
			switch self {
			case .string: return "text.quote"
			case .boolean: return "checkmark.circle"
			case .number: return "number"
			case .array: return "list.bullet"
			}
		}
	}
	
	var body: some View {
		NBList(.localized("Custom Info.plist Entries")) {
			// Preset Options Section
			NBSection(.localized("Preset Options"), systemName: "sparkles") {
				Button {
					showPresetSheet = true
				} label: {
					HStack(spacing: 12) {
						ZStack {
							Circle()
								.fill(
									LinearGradient(
										colors: [Color.purple, Color.blue, Color.purple.opacity(0.7)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 40, height: 40)
								.shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 3)
							
							Image(systemName: "star.fill")
								.font(.system(size: 18))
								.foregroundStyle(.white)
						}
						
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Add Preset Options"))
								.font(.body)
								.foregroundStyle(.primary)
							
							Text(.localized("Orientation, Background Modes, etc."))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						
						Spacer()
						
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					.padding(.vertical, 4)
				}
				.buttonStyle(.plain)
			}
			
			// Import Section
			NBSection(.localized("Import"), systemName: "arrow.down.doc") {
				Button {
					showImportSheet = true
				} label: {
					HStack(spacing: 12) {
						ZStack {
							Circle()
								.fill(
									LinearGradient(
										colors: [Color.green, Color.cyan, Color.green.opacity(0.7)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 40, height: 40)
								.shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 3)
							
							Image(systemName: "square.and.arrow.down")
								.font(.system(size: 18))
								.foregroundStyle(.white)
						}
						
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Import Info.plist File"))
								.font(.body)
								.foregroundStyle(.primary)
							
							Text(.localized("Upload custom plist file"))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						
						Spacer()
						
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					.padding(.vertical, 4)
				}
				.buttonStyle(.plain)
			}
			
			// Custom Entries Section
			NBSection(.localized("Custom Entries"), systemName: "key.fill") {
				if options.customInfoPlistEntries.isEmpty {
					HStack {
						Spacer()
						VStack(spacing: 12) {
							ZStack {
								Circle()
									.fill(
										LinearGradient(
											colors: [
												Color.orange.opacity(0.3),
												Color.pink.opacity(0.2),
												Color.orange.opacity(0.1)
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 50, height: 50)
									.shadow(color: Color.orange.opacity(0.4), radius: 10, x: 0, y: 4)
								
								Image(systemName: "doc.text")
									.font(.system(size: 40))
									.foregroundStyle(
										LinearGradient(
											colors: [Color.orange, Color.pink, Color.orange.opacity(0.7)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							}
							
							Text(verbatim: .localized("No Custom Entries"))
								.font(.subheadline)
								.foregroundStyle(
									LinearGradient(
										colors: [Color.secondary, Color.secondary.opacity(0.7)],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
						}
						.padding(.vertical, 20)
						Spacer()
					}
				} else {
					ForEach(Array(options.customInfoPlistEntries.keys.sorted()), id: \.self) { key in
						entryRow(key: key)
					}
				}
			}
		}
		.toolbar {
			NBToolbarButton(
				systemImage: "plus",
				style: .icon,
				placement: .topBarTrailing
			) {
				showAddEntryDialog = true
			}
		}
		.sheet(isPresented: $showAddEntryDialog) {
			addEntrySheet
		}
		.sheet(isPresented: $showPresetSheet) {
			presetOptionsSheet
		}
		.sheet(isPresented: $showImportSheet) {
			FileImporterRepresentableView(
				allowedContentTypes: [.propertyList, .xml],
				allowsMultipleSelection: false,
				onDocumentsPicked: { urls in
					guard let url = urls.first else { return }
					importPlistFile(url: url)
				}
			)
			.ignoresSafeArea()
		}
		.animation(.spring(response: 0.5, dampingFraction: 0.8), value: options.customInfoPlistEntries)
	}
	
	@ViewBuilder
	private func entryRow(key: String) -> some View {
		HStack(spacing: 12) {
			ZStack {
				Circle()
					.fill(
						LinearGradient(
							colors: [Color.accentColor, Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.6)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: 40, height: 40)
					.shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 3)
				
				Image(systemName: valueTypeIcon(for: options.customInfoPlistEntries[key]?.value))
					.font(.system(size: 18))
					.foregroundStyle(.white)
			}
			
			VStack(alignment: .leading, spacing: 2) {
				Text(key)
					.font(.body)
					.lineLimit(1)
				
				Text(valueDescription(for: options.customInfoPlistEntries[key]?.value))
					.font(.caption)
					.foregroundStyle(.secondary)
					.lineLimit(1)
			}
			
			Spacer()
		}
		.padding(.vertical, 4)
		.swipeActions(edge: .trailing, allowsFullSwipe: true) {
			Button(role: .destructive) {
				withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
					_ = options.customInfoPlistEntries.removeValue(forKey: key)
				}
			} label: {
				Label(.localized("Delete"), systemImage: "trash")
			}
		}
		.contextMenu {
			Button(role: .destructive) {
				withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
					_ = options.customInfoPlistEntries.removeValue(forKey: key)
				}
			} label: {
				Label(.localized("Delete"), systemImage: "trash")
			}
		}
	}
	
	private func valueTypeIcon(for value: Any?) -> String {
		guard let value = value else { return "questionmark" }
		
		if value is String {
			return "text.quote"
		} else if value is Bool {
			return "checkmark.circle"
		} else if value is Int || value is Double || value is Float {
			return "number"
		} else if value is [Any] {
			return "list.bullet"
		} else if value is [String: Any] {
			return "curlybraces"
		} else {
			return "questionmark"
		}
	}
	
	private func valueDescription(for value: Any?) -> String {
		guard let value = value else { return "Unknown" }
		
		if let string = value as? String {
			return string
		} else if let bool = value as? Bool {
			return bool ? "true" : "false"
		} else if let number = value as? Int {
			return "\(number)"
		} else if let number = value as? Double {
			return "\(number)"
		} else if let array = value as? [Any] {
			return "Array (\(array.count) items)"
		} else if let dict = value as? [String: Any] {
			return "Dictionary (\(dict.count) keys)"
		} else {
			return "\(value)"
		}
	}
	
	@ViewBuilder
	private var addEntrySheet: some View {
		NBNavigationView(.localized("Add Entry"), displayMode: .inline) {
			Form {
				Section {
					TextField(.localized("Key"), text: $newKey)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
				} header: {
					Text(.localized("Key"))
				}
				
				Section {
					Picker(.localized("Type"), selection: $newValueType) {
						ForEach(InfoPlistValueType.allCases, id: \.self) { type in
							Label(type.rawValue, systemImage: type.icon)
								.tag(type)
						}
					}
					.pickerStyle(.segmented)
					
					switch newValueType {
					case .string:
						TextField(.localized("Value"), text: $newStringValue)
					case .boolean:
						Toggle(.localized("Value"), isOn: $newBoolValue)
					case .number:
						TextField(.localized("Value"), text: $newNumberValue)
							.keyboardType(.numbersAndPunctuation)
					case .array:
						Text(.localized("Array values can be added after creation"))
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				} header: {
					Text(.localized("Value"))
				}
				
				Section {
					Button {
						addEntry()
					} label: {
						Text(.localized("Add"))
							.frame(maxWidth: .infinity)
					}
					.disabled(newKey.isEmpty)
				}
			}
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(.localized("Cancel")) {
						showAddEntryDialog = false
						resetForm()
					}
				}
			}
		}
	}
	
	@ViewBuilder
	private var presetOptionsSheet: some View {
		NBNavigationView(.localized("Preset Options"), displayMode: .inline) {
			List {
				Section {
					Button {
						addOrientationPreset(.portrait)
					} label: {
						presetRow(
							title: "Portrait Only",
							description: "Lock orientation to portrait",
							icon: "rectangle.portrait",
							color: .blue
						)
					}
					
					Button {
						addOrientationPreset(.landscape)
					} label: {
						presetRow(
							title: "Landscape Only",
							description: "Lock orientation to landscape",
							icon: "rectangle",
							color: .green
						)
					}
					
					Button {
						addOrientationPreset(.all)
					} label: {
						presetRow(
							title: "All Orientations",
							description: "Allow all device orientations",
							icon: "rotate.3d",
							color: .purple
						)
					}
				} header: {
					Text(.localized("App Orientation"))
				}
				
				Section {
					Button {
						addBackgroundMode(.audio)
					} label: {
						presetRow(
							title: "Background Audio",
							description: "Play audio in background",
							icon: "music.note",
							color: .pink
						)
					}
					
					Button {
						addBackgroundMode(.location)
					} label: {
						presetRow(
							title: "Background Location",
							description: "Access location in background",
							icon: "location",
							color: .orange
						)
					}
					
					Button {
						addBackgroundMode(.voip)
					} label: {
						presetRow(
							title: "VoIP",
							description: "Voice over IP in background",
							icon: "phone",
							color: .indigo
						)
					}
					
					Button {
						addBackgroundMode(.fetch)
					} label: {
						presetRow(
							title: "Background Fetch",
							description: "Fetch content in background",
							icon: "arrow.down.circle",
							color: .teal
						)
					}
				} header: {
					Text(.localized("Background Modes"))
				}
				
				Section {
					Button {
						addSimpleEntry(key: "UIFileSharingEnabled", value: true)
					} label: {
						presetRow(
							title: "File Sharing",
							description: "Enable iTunes file sharing",
							icon: "folder",
							color: .cyan
						)
					}
					
					Button {
						addSimpleEntry(key: "UISupportsDocumentBrowser", value: true)
					} label: {
						presetRow(
							title: "Document Browser",
							description: "Support document browser",
							icon: "doc",
							color: .brown
						)
					}
				} header: {
					Text(.localized("File Access"))
				}
			}
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(.localized("Done")) {
						showPresetSheet = false
					}
				}
			}
		}
	}
	
	@ViewBuilder
	private func presetRow(title: String, description: String, icon: String, color: Color) -> some View {
		HStack(spacing: 12) {
			ZStack {
				RoundedRectangle(cornerRadius: 8, style: .continuous)
					.fill(color.opacity(0.15))
					.frame(width: 40, height: 40)
				Image(systemName: icon)
					.font(.system(size: 18))
					.foregroundStyle(color)
			}
			
			VStack(alignment: .leading, spacing: 2) {
				Text(.localized(title))
					.font(.body)
					.foregroundStyle(.primary)
				Text(.localized(description))
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			
			Spacer()
		}
	}
	
	private enum Orientation {
		case portrait, landscape, all
	}
	
	private enum BackgroundMode: String {
		case audio = "audio"
		case location = "location"
		case voip = "voip"
		case fetch = "fetch"
	}
	
	private func addOrientationPreset(_ orientation: Orientation) {
		let orientations: [String]
		switch orientation {
		case .portrait:
			orientations = ["UIInterfaceOrientationPortrait"]
		case .landscape:
			orientations = ["UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"]
		case .all:
			orientations = [
				"UIInterfaceOrientationPortrait",
				"UIInterfaceOrientationPortraitUpsideDown",
				"UIInterfaceOrientationLandscapeLeft",
				"UIInterfaceOrientationLandscapeRight"
			]
		}
		
		withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
			options.customInfoPlistEntries["UISupportedInterfaceOrientations"] = AnyCodable(orientations)
		}
		
		HapticsManager.shared.success()
		showPresetSheet = false
	}
	
	private func addBackgroundMode(_ mode: BackgroundMode) {
		var modes: [String] = []
		
		if let existing = options.customInfoPlistEntries["UIBackgroundModes"]?.value as? [String] {
			modes = existing
		}
		
		if !modes.contains(mode.rawValue) {
			modes.append(mode.rawValue)
		}
		
		withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
			options.customInfoPlistEntries["UIBackgroundModes"] = AnyCodable(modes)
		}
		
		HapticsManager.shared.success()
		showPresetSheet = false
	}
	
	private func addSimpleEntry(key: String, value: Any) {
		withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
			options.customInfoPlistEntries[key] = AnyCodable(value)
		}
		
		HapticsManager.shared.success()
		showPresetSheet = false
	}
	
	private func addEntry() {
		guard !newKey.isEmpty else { return }
		
		let value: Any
		switch newValueType {
		case .string:
			value = newStringValue
		case .boolean:
			value = newBoolValue
		case .number:
			if let intValue = Int(newNumberValue) {
				value = intValue
			} else if let doubleValue = Double(newNumberValue) {
				value = doubleValue
			} else {
				value = newNumberValue
			}
		case .array:
			value = [String]()
		}
		
		withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
			options.customInfoPlistEntries[newKey] = AnyCodable(value)
		}
		
		HapticsManager.shared.success()
		showAddEntryDialog = false
		resetForm()
	}
	
	private func importPlistFile(url: URL) {
		do {
			let data = try Data(contentsOf: url)
			guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
				UIAlertController.showAlertWithOk(
					title: .localized("Error"),
					message: .localized("Invalid plist format")
				)
				return
			}
			
			// Merge imported entries with existing ones
			withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
				for (key, value) in plist {
					options.customInfoPlistEntries[key] = AnyCodable(value)
				}
			}
			
			HapticsManager.shared.success()
			UIAlertController.showAlertWithOk(
				title: .localized("Success"),
				message: .localized("Imported \(plist.count) entries from plist")
			)
		} catch {
			HapticsManager.shared.error()
			UIAlertController.showAlertWithOk(
				title: .localized("Error"),
				message: .localized("Failed to import plist: \(error.localizedDescription)")
			)
		}
	}
	
	private func resetForm() {
		newKey = ""
		newValueType = .string
		newStringValue = ""
		newBoolValue = false
		newNumberValue = ""
	}
}
