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
			case .boolean: return "checkmark.circle.fill"
			case .number: return "number.circle.fill"
			case .array: return "list.bullet.circle.fill"
			}
		}
	}
	
	var body: some View {
		NBList(.localized("Custom Info.plist Entries")) {
			// Preset Options Section
			NBSection(.localized("Preset Options"), systemName: "sparkles.rectangle.stack.fill") {
				Button {
					showPresetSheet = true
				} label: {
					Label {
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Add Preset Options"))
								.font(.body)
							Text(.localized("Orientation, Background Modes, etc."))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					} icon: {
						Image(systemName: "star.circle.fill")
							.font(.title2)
							.foregroundStyle(.purple)
					}
				}
			}
			
			// Import Section
			NBSection(.localized("Import"), systemName: "arrow.down.doc.fill") {
				Button {
					showImportSheet = true
				} label: {
					Label {
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Import Info.plist File"))
								.font(.body)
							Text(.localized("Upload custom plist file"))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					} icon: {
						Image(systemName: "square.and.arrow.down.fill")
							.font(.title2)
							.foregroundStyle(.green)
					}
				}
			}
			
			// Custom Entries Section
			NBSection(.localized("Custom Entries"), systemName: "key.fill") {
				if options.customInfoPlistEntries.isEmpty {
					ContentUnavailableView {
						Label("No Custom Entries", systemImage: "doc.text.fill")
					} description: {
						Text("Add custom Info.plist entries using the + button")
					}
					.frame(maxWidth: .infinity)
					.padding()
				} else {
					ForEach(Array(options.customInfoPlistEntries.keys.sorted()), id: \.self) { key in
						entryRow(key: key)
					}
				}
			}
		}
		.toolbar {
			NBToolbarButton(
				systemImage: "plus.circle.fill",
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
		.animation(.default, value: options.customInfoPlistEntries)
	}
	
	@ViewBuilder
	private func entryRow(key: String) -> some View {
		Label {
			VStack(alignment: .leading, spacing: 2) {
				Text(key)
					.font(.body)
				Text(valueDescription(for: options.customInfoPlistEntries[key]?.value))
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		} icon: {
			Image(systemName: valueTypeIcon(for: options.customInfoPlistEntries[key]?.value))
				.font(.title3)
				.foregroundStyle(.blue)
		}
		.swipeActions(edge: .trailing, allowsFullSwipe: true) {
			Button(role: .destructive) {
				withAnimation {
					_ = options.customInfoPlistEntries.removeValue(forKey: key)
				}
			} label: {
				Label(.localized("Delete"), systemImage: "trash.fill")
			}
		}
		.contextMenu {
			Button(role: .destructive) {
				withAnimation {
					_ = options.customInfoPlistEntries.removeValue(forKey: key)
				}
			} label: {
				Label(.localized("Delete"), systemImage: "trash.fill")
			}
		}
	}
	
	private func valueTypeIcon(for value: Any?) -> String {
		guard let value = value else { return "questionmark.circle.fill" }
		
		if value is String {
			return "text.quote"
		} else if value is Bool {
			return "checkmark.circle.fill"
		} else if value is Int || value is Double || value is Float {
			return "number.circle.fill"
		} else if value is [Any] {
			return "list.bullet.circle.fill"
		} else if value is [String: Any] {
			return "curlybraces.square.fill"
		} else {
			return "questionmark.circle.fill"
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
					Label("Key", systemImage: "key.fill")
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
					Label("Value", systemImage: "text.alignleft")
				}
				
				Section {
					Button {
						addEntry()
					} label: {
						Label("Add", systemImage: "plus.circle.fill")
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
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text("Portrait Only")
									.font(.body)
								Text("Lock orientation to portrait")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "rectangle.portrait.fill")
								.foregroundStyle(.blue)
						}
					}
					
					Button {
						addOrientationPreset(.landscape)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text("Landscape Only")
									.font(.body)
								Text("Lock orientation to landscape")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "rectangle.fill")
								.foregroundStyle(.green)
						}
					}
					
					Button {
						addOrientationPreset(.all)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text("All Orientations")
									.font(.body)
								Text("Allow all device orientations")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "rotate.3d.fill")
								.foregroundStyle(.purple)
						}
					}
				} header: {
					Label("App Orientation", systemImage: "rotate.right.fill")
				}
				
				Section {
					Button {
						addBackgroundMode(.audio)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text("Background Audio")
									.font(.body)
								Text("Play audio in background")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "music.note.circle.fill")
								.foregroundStyle(.pink)
						}
					}
					
					Button {
						addBackgroundMode(.location)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text("Background Location")
									.font(.body)
								Text("Access location in background")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "location.circle.fill")
								.foregroundStyle(.orange)
						}
					}
					
					Button {
						addBackgroundMode(.voip)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text("VoIP")
									.font(.body)
								Text("Voice over IP in background")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "phone.circle.fill")
								.foregroundStyle(.indigo)
						}
					}
					
					Button {
						addBackgroundMode(.fetch)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text("Background Fetch")
									.font(.body)
								Text("Fetch content in background")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "arrow.down.circle.fill")
								.foregroundStyle(.teal)
						}
					}
				} header: {
					Label("Background Modes", systemImage: "gear.circle.fill")
				}
				
				Section {
					Button {
						addSimpleEntry(key: "UIFileSharingEnabled", value: true)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text("File Sharing")
									.font(.body)
								Text("Enable iTunes file sharing")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "folder.fill")
								.foregroundStyle(.cyan)
						}
					}
					
					Button {
						addSimpleEntry(key: "UISupportsDocumentBrowser", value: true)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text("Document Browser")
									.font(.body)
								Text("Support document browser")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "doc.fill")
								.foregroundStyle(.brown)
						}
					}
				} header: {
					Label("File Access", systemImage: "filemenu.and.selection")
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
		
		withAnimation {
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
		
		withAnimation {
			options.customInfoPlistEntries["UIBackgroundModes"] = AnyCodable(modes)
		}
		
		HapticsManager.shared.success()
		showPresetSheet = false
	}
	
	private func addSimpleEntry(key: String, value: Any) {
		withAnimation {
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
		
		withAnimation {
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
			withAnimation {
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
