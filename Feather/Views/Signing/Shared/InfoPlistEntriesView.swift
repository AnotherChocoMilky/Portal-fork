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
							Text(.localized("Upload Custom .plist File"))
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
			
			// Export Section
			NBSection(.localized("Export"), systemName: "arrow.up.doc.fill") {
				Button {
					exportPlistFile()
				} label: {
					Label {
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Export Entries To File"))
								.font(.body)
							Text(.localized("Save Current Entries As .plist"))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					} icon: {
						Image(systemName: "square.and.arrow.up.fill")
							.font(.title2)
							.foregroundStyle(.blue)
					}
				}
				.disabled(options.customInfoPlistEntries.isEmpty)
			}
			
			// Custom Entries Section
			NBSection(.localized("Custom Entries"), systemName: "key.fill") {
				if options.customInfoPlistEntries.isEmpty {
					if #available(iOS 17.0, *) {
						ContentUnavailableView {
							Label(.localized("No Custom Entries"), systemImage: "doc.text.fill")
						} description: {
							Text(.localized("Add custom Info.plist entries using the + button."))
						}
						.frame(maxWidth: .infinity)
						.padding()
					} else {
						VStack {
							Label(.localized("No Custom Entries"), systemImage: "doc.text.fill")
							Text(.localized("Add custom Info.plist entries using the + button."))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						.frame(maxWidth: .infinity)
						.padding()
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
			return "Array (\(array.count) Items)"
		} else if let dict = value as? [String: Any] {
			return "Dictionary (\(dict.count) Keys)"
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
					Label(.localized("Key"), systemImage: "key.fill")
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
					Label(.localized("Value"), systemImage: "text.alignleft")
				}
				
				Section {
					Button {
						addEntry()
					} label: {
						Label(.localized("Add"), systemImage: "plus.circle.fill")
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
								Text(.localized("Portrait Only"))
									.font(.body)
								Text(.localized("Lock Orientation To Portrait"))
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
								Text(.localized("Landscape Only"))
									.font(.body)
								Text(.localized("Lock Orientation To Landscape"))
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
								Text(.localized("All Orientations"))
									.font(.body)
								Text(.localized("Allow All Device Orientations"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "rotate.3d.fill")
								.foregroundStyle(.purple)
						}
					}
				} header: {
					Label(.localized("App Orientation"), systemImage: "rotate.right.fill")
				}
				
				Section {
					Button {
						addBackgroundMode(.audio)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Background Audio"))
									.font(.body)
								Text(.localized("Play Audio In Background"))
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
								Text(.localized("Background Location"))
									.font(.body)
								Text(.localized("Access Location In Background"))
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
								Text(.localized("VoIP"))
									.font(.body)
								Text(.localized("Voice Over IP In Background"))
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
								Text(.localized("Background Fetch"))
									.font(.body)
								Text(.localized("Fetch Content In Background"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "arrow.down.circle.fill")
								.foregroundStyle(.teal)
						}
					}
					
					Button {
						addBackgroundMode(.processing)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Background Processing"))
									.font(.body)
								Text(.localized("Run Background Tasks"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "cpu.fill")
								.foregroundStyle(.purple)
						}
					}
					
					Button {
						addBackgroundMode(.remoteNotification)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Remote Notifications"))
									.font(.body)
								Text(.localized("Receive Push Notifications. Note this might not work as intended."))
									.font(.caption)
									.foregroundStyle(.secondary)
						}
					} icon: {
							Image(systemName: "bell.badge.fill")
								.foregroundStyle(.red)
						}
					}
				} header: {
					Label(.localized("Background Modes"), systemImage: "gear.circle.fill")
				}
				
				Section {
					Button {
						addSimpleEntry(key: "UIRequiresFullScreen", value: true)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Require Full Screen"))
									.font(.body)
								Text(.localized("App Requires Full Screen Mode"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "rectangle.expand.vertical")
								.foregroundStyle(.purple)
						}
					}
					
					Button {
						addSimpleEntry(key: "UIStatusBarHidden", value: true)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Hide Status Bar"))
									.font(.body)
								Text(.localized("Hide The Status Bar On The App"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "eye.slash.fill")
								.foregroundStyle(.gray)
						}
					}
					
					Button {
						addSimpleEntry(key: "UILaunchStoryboardName", value: "LaunchScreen")
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Launch Screen"))
									.font(.body)
								Text(.localized("Set Launch Screen Name"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "play.rectangle.fill")
								.foregroundStyle(.green)
						}
					}
				} header: {
					Label(.localized("Display & UI"), systemImage: "paintbrush.fill")
				}
				
				Section {
					Button {
						addSimpleEntry(key: "UIFileSharingEnabled", value: true)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("File Sharing"))
									.font(.body)
								Text(.localized("Enable iTunes File Sharing"))
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
								Text(.localized("Document Browser"))
									.font(.body)
								Text(.localized("Support Document Browser"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "doc.fill")
								.foregroundStyle(.brown)
						}
					}
				} header: {
					Label(.localized("File Access"), systemImage: "filemenu.and.selection")
				}
				
				Section {
					Button {
						addSimpleEntry(key: "NSCameraUsageDescription", value: "This app needs camera access. Modified .plist entry.")
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Camera Usage"))
									.font(.body)
								Text(.localized("Add Camera Permission Description"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "camera.fill")
								.foregroundStyle(.blue)
						}
					}
					
					Button {
						addSimpleEntry(key: "NSPhotoLibraryUsageDescription", value: "This app needs photo library access. Modified .plist entry.")
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Photo Library Usage"))
									.font(.body)
								Text(.localized("Add Photo Library Permission"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "photo.fill")
								.foregroundStyle(.purple)
						}
					}
					
					Button {
						addSimpleEntry(key: "NSMicrophoneUsageDescription", value: "This app needs microphone access. Modified .plist entry.")
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Microphone Usage"))
									.font(.body)
								Text(.localized("Add Microphone Permission"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "mic.fill")
								.foregroundStyle(.red)
						}
					}
					
					Button {
						addSimpleEntry(key: "NSLocationWhenInUseUsageDescription", value: "This app needs location access. Modified .plist entry.")
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Location Usage"))
									.font(.body)
								Text(.localized("Add Location Permission"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "location.fill")
								.foregroundStyle(.green)
						}
					}
				} header: {
					Label(.localized("Privacy Permissions"), systemImage: "hand.raised.fill")
				}
				
				Section {
					Button {
						addURLScheme("myapp")
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Add URL Scheme"))
									.font(.body)
								Text(.localized("Custom URL Scheme For Deep Linking"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "link.circle.fill")
								.foregroundStyle(.orange)
						}
					}
				} header: {
					Label(.localized("URL Schemes"), systemImage: "link.badge.plus")
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
		case processing = "processing"
		case remoteNotification = "remote-notification"
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
	
	private func addURLScheme(_ scheme: String) {
		// CFBundleURLTypes is an array of dictionaries
		var urlTypes: [[String: Any]] = []
		
		if let existing = options.customInfoPlistEntries["CFBundleURLTypes"]?.value as? [[String: Any]] {
			urlTypes = existing
		}
		
		// Add new URL type
		let newType: [String: Any] = [
			"CFBundleURLName": scheme,
			"CFBundleURLSchemes": [scheme]
		]
		urlTypes.append(newType)
		
		withAnimation {
			options.customInfoPlistEntries["CFBundleURLTypes"] = AnyCodable(urlTypes)
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
					message: .localized("Invalid Plist Format")
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
				message: .localized("Imported \(plist.count) Entries From .plist file.")
			)
		} catch {
			HapticsManager.shared.error()
			UIAlertController.showAlertWithOk(
				title: .localized("Error"),
				message: .localized("Failed to import plist: \(error.localizedDescription)")
			)
		}
	}
	
	private func exportPlistFile() {
		do {
			// Convert AnyCodable entries to plain dictionary
			var exportDict: [String: Any] = [:]
			for (key, anyCodable) in options.customInfoPlistEntries {
				exportDict[key] = anyCodable.value
			}
			
			// Serialize to plist format
			let data = try PropertyListSerialization.data(fromPropertyList: exportDict, format: .xml, options: 0)
			
			// Create temp file
			let tempDir = FileManager.default.temporaryDirectory
			let fileName = "ModifiedInfoPlistEntries_\(Date().timeIntervalSince1970).plist"
			let fileURL = tempDir.appendingPathComponent(fileName)
			
			// Write data
			try data.write(to: fileURL)
			
			// Share the file
			let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
			if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			   let window = windowScene.windows.first,
			   let rootVC = window.rootViewController {
				var topVC = rootVC
				while let presented = topVC.presentedViewController {
					topVC = presented
				}
				activityVC.popoverPresentationController?.sourceView = topVC.view
				activityVC.popoverPresentationController?.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
				activityVC.popoverPresentationController?.permittedArrowDirections = []
				topVC.present(activityVC, animated: true)
			}
			
			HapticsManager.shared.success()
		} catch {
			HapticsManager.shared.error()
			UIAlertController.showAlertWithOk(
				title: .localized("Error"),
				message: .localized("Failed to export plist: \(error.localizedDescription)")
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
