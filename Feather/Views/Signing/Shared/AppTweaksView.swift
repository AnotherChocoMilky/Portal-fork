import SwiftUI
import NimbleViews
import ZsignSwift
import Zip

// MARK: - App Tweaks View
struct AppTweaksView: View {
	@Environment(\.dismiss) var dismiss
	@Environment(\.colorScheme) var colorScheme
	
	var app: AppInfoPresentable
	@Binding var options: Options
	
	@State private var selectedTab = 0
	@State private var expandedFrameworks = false
	@State private var expandedBundles = false
	@State private var showExtractView = false
	@State private var searchText = ""
	@FocusState private var searchFieldFocused: Bool
	
	// Data
	@State private var dylibs: [String] = []
	@State private var frameworks: [String] = []
	@State private var bundles: [String] = []
	@State private var injectionFiles: [URL] = []
	
	var body: some View {
		ZStack {
			// Background
			Color(UIColor.systemBackground)
				.ignoresSafeArea()
			
			VStack(spacing: 0) {
				// Navigation Bar
				navigationBar
				
				// Primary Action Area
				primaryActionArea
					.padding(.horizontal, 20)
					.padding(.top, 16)
				
				// Content
				ScrollView {
					VStack(spacing: 24) {
						// Overview Section
						overviewSection
							.padding(.horizontal, 20)
						
						// Tweaks List Section
						tweaksListSection
							.padding(.horizontal, 20)
					}
					.padding(.vertical, 20)
				}
			}
		}
		.navigationBarHidden(true)
		.onAppear {
			loadData()
			injectionFiles = options.injectionFiles
		}
		.sheet(isPresented: $showExtractView) {
			ExtractTweaksView(
				app: app,
				frameworks: frameworks,
				bundles: bundles
			)
		}
	}
	
	// MARK: - Navigation Bar
	@ViewBuilder
	private var navigationBar: some View {
		HStack(spacing: 16) {
			// Back Button
			Button {
				dismiss()
			} label: {
				ZStack {
					Circle()
						.fill(Color(UIColor.secondarySystemGroupedBackground))
						.frame(width: 36, height: 36)
					
					Image(systemName: "chevron.left")
						.font(.system(size: 14, weight: .semibold))
						.foregroundStyle(.primary)
				}
			}
			
			Spacer()
			
			// Title
			Text("App Tweaks")
				.font(.system(size: 17, weight: .semibold))
				.foregroundStyle(.primary)
			
			Spacer()
			
			// Three-Dot Menu
			Menu {
				Button {
					enableAll()
				} label: {
					Label("Enable All", systemImage: "checkmark.circle")
				}
				
				Button {
					disableAll()
				} label: {
					Label("Disable All", systemImage: "xmark.circle")
				}
				
				Divider()
				
				Button {
					expandAll()
				} label: {
					Label("Expand All", systemImage: "arrow.up.left.and.arrow.down.right")
				}
				
				Button {
					collapseAll()
				} label: {
					Label("Collapse All", systemImage: "arrow.down.right.and.arrow.up.left")
				}
			} label: {
				ZStack {
					Circle()
						.fill(Color(UIColor.secondarySystemGroupedBackground))
						.frame(width: 36, height: 36)
					
					Image(systemName: "ellipsis")
						.font(.system(size: 14, weight: .semibold))
						.foregroundStyle(.primary)
				}
			}
		}
		.padding(.horizontal, 20)
		.padding(.top, 8)
		.padding(.bottom, 8)
	}
	
	// MARK: - Primary Action Area
	@ViewBuilder
	private var primaryActionArea: some View {
		VStack(spacing: 12) {
			// Segmented Control
			Picker("Mode", selection: $selectedTab) {
				Text("Enable/Disable for Signing")
					.tag(0)
				Text("Extract Tweaks")
					.tag(1)
			}
			.pickerStyle(.segmented)
			.padding(4)
			.background(
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.fill(Color(UIColor.tertiarySystemGroupedBackground))
			)
			
			// Informational Bar
			HStack(spacing: 8) {
				Image(systemName: "info.circle.fill")
					.font(.system(size: 12))
					.foregroundStyle(Color(UIColor.secondaryLabel))
				
				Text("Enabled tweaks will be injected when signing this app")
					.font(.system(size: 13, weight: .medium))
					.foregroundStyle(Color(UIColor.secondaryLabel))
				
				Spacer()
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 10)
			.background(
				RoundedRectangle(cornerRadius: 10, style: .continuous)
					.fill(Color(UIColor.secondarySystemGroupedBackground))
			)
			
			// Search Bar
			HStack(spacing: 10) {
				Image(systemName: "magnifyingglass")
					.font(.system(size: 14))
					.foregroundStyle(Color(UIColor.secondaryLabel))
				
				TextField("Search Tweaks", text: $searchText)
					.font(.system(size: 15))
					.focused($searchFieldFocused)
				
				if !searchText.isEmpty {
					Button {
						searchText = ""
						searchFieldFocused = false
					} label: {
						Image(systemName: "xmark.circle.fill")
							.font(.system(size: 16))
							.foregroundStyle(Color(UIColor.tertiaryLabel))
					}
				}
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 10)
			.background(
				RoundedRectangle(cornerRadius: 10, style: .continuous)
					.fill(Color(UIColor.secondarySystemGroupedBackground))
			)
			.overlay(
				RoundedRectangle(cornerRadius: 10, style: .continuous)
					.stroke(searchFieldFocused ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
			)
		}
		.onChange(of: selectedTab) { newValue in
			if newValue == 1 {
				// Show extract view
				showExtractView = true
				// Reset to tab 0 after showing
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					selectedTab = 0
				}
			}
		}
	}
	
	// MARK: - Overview Section
	@ViewBuilder
	private var overviewSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			// Section Header
			Text("Overview")
				.font(.system(size: 12, weight: .semibold))
				.foregroundStyle(Color(UIColor.secondaryLabel))
				.padding(.leading, 4)
			
			// Stats Card
			VStack(spacing: 16) {
				// Three columns
				HStack(spacing: 0) {
					statsColumn(
						count: frameworks.count,
						label: "Frameworks"
					)
					
					Divider()
						.frame(height: 40)
					
					statsColumn(
						count: dylibs.count,
						label: "Dylibs"
					)
					
					Divider()
						.frame(height: 40)
					
					statsColumn(
						count: bundles.count,
						label: "Bundles"
					)
				}
				
				Divider()
				
				// Total
				HStack {
					Text("Total Tweaks")
						.font(.system(size: 15, weight: .medium))
						.foregroundStyle(.primary)
					
					Spacer()
					
					Text("\(frameworks.count + dylibs.count + bundles.count)")
						.font(.system(size: 15, weight: .semibold))
						.foregroundStyle(.primary)
				}
				.padding(.horizontal, 16)
			}
			.padding(.vertical, 16)
			.background(
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.fill(Color(UIColor.secondarySystemGroupedBackground))
			)
		}
	}
	
	@ViewBuilder
	private func statsColumn(count: Int, label: String) -> some View {
		VStack(spacing: 6) {
			Text("\(count)")
				.font(.system(size: 32, weight: .bold))
				.foregroundStyle(.primary)
			
			Text(label)
				.font(.system(size: 13, weight: .medium))
				.foregroundStyle(Color(UIColor.secondaryLabel))
		}
		.frame(maxWidth: .infinity)
	}
	
	// MARK: - Tweaks List Section
	@ViewBuilder
	private var tweaksListSection: some View {
		VStack(spacing: 12) {
			// Frameworks Row
			Button {
				withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
					expandedFrameworks.toggle()
				}
			} label: {
				tweakRow(
					title: "Frameworks",
					count: frameworks.count,
					icon: "cube.fill",
					color: .blue,
					isExpanded: expandedFrameworks
				)
			}
			.buttonStyle(.plain)
			
			if expandedFrameworks {
				frameworksList
					.transition(.opacity.combined(with: .move(edge: .top)))
			}
			
			// Bundles Row
			Button {
				withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
					expandedBundles.toggle()
				}
			} label: {
				tweakRow(
					title: "Bundles",
					count: bundles.count,
					icon: "shippingbox.fill",
					color: .purple,
					isExpanded: expandedBundles
				)
			}
			.buttonStyle(.plain)
			
			if expandedBundles {
				bundlesList
					.transition(.opacity.combined(with: .move(edge: .top)))
			}
		}
	}
	
	@ViewBuilder
	private func tweakRow(title: String, count: Int, icon: String, color: Color, isExpanded: Bool) -> some View {
		HStack(spacing: 14) {
			// Icon
			ZStack {
				RoundedRectangle(cornerRadius: 10, style: .continuous)
					.fill(color.opacity(0.15))
					.frame(width: 44, height: 44)
				
				Image(systemName: icon)
					.font(.system(size: 20))
					.foregroundStyle(color)
			}
			
			// Title and Count
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.system(size: 16, weight: .semibold))
					.foregroundStyle(.primary)
				
				Text("\(count) Items")
					.font(.system(size: 13))
					.foregroundStyle(Color(UIColor.secondaryLabel))
			}
			
			Spacer()
			
			// Chevron
			Image(systemName: isExpanded ? "chevron.up" : "chevron.right")
				.font(.system(size: 14, weight: .semibold))
				.foregroundStyle(Color(UIColor.tertiaryLabel))
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 14, style: .continuous)
				.fill(Color(UIColor.secondarySystemGroupedBackground))
		)
	}
	
	// MARK: - Frameworks List
	@ViewBuilder
	private var frameworksList: some View {
		let filteredFrameworks = searchText.isEmpty ? frameworks : frameworks.filter { $0.localizedCaseInsensitiveContains(searchText) }
		
		VStack(spacing: 8) {
			if filteredFrameworks.isEmpty {
				Text("No Matching Frameworks")
					.font(.system(size: 14))
					.foregroundStyle(.secondary)
					.padding()
			} else {
				ForEach(filteredFrameworks, id: \.self) { framework in
					tweakItemRow(
						name: framework,
						isEnabled: !options.removeFiles.contains("Frameworks/\(framework)"),
						onToggle: {
							toggleFramework(framework)
						},
						onRemove: {
							removeFramework(framework)
						}
					)
				}
			}
		}
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(Color(UIColor.tertiarySystemGroupedBackground))
		)
	}
	
	// MARK: - Bundles List
	@ViewBuilder
	private var bundlesList: some View {
		let filteredBundles = searchText.isEmpty ? bundles : bundles.filter { $0.localizedCaseInsensitiveContains(searchText) }
		
		VStack(spacing: 8) {
			if filteredBundles.isEmpty {
				Text("No Matching Bundles")
					.font(.system(size: 14))
					.foregroundStyle(.secondary)
					.padding()
			} else {
				ForEach(filteredBundles, id: \.self) { bundle in
					tweakItemRow(
						name: bundle,
						isEnabled: !options.removeFiles.contains("PlugIns/\(bundle)"),
						onToggle: {
							toggleBundle(bundle)
						},
						onRemove: {
							removeBundle(bundle)
						}
					)
				}
			}
		}
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(Color(UIColor.tertiarySystemGroupedBackground))
		)
	}
	
	@ViewBuilder
	private func tweakItemRow(name: String, isEnabled: Bool, onToggle: @escaping () -> Void, onRemove: @escaping () -> Void) -> some View {
		HStack(spacing: 12) {
			// Toggle
			Button {
				onToggle()
			} label: {
				ZStack {
					Circle()
						.fill(isEnabled ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
						.frame(width: 32, height: 32)
					
					Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
						.font(.system(size: 18))
						.foregroundStyle(isEnabled ? Color.green : Color.gray)
				}
			}
			.buttonStyle(.plain)
			
			// Name
			Text(name)
				.font(.system(size: 14, weight: .medium))
				.foregroundStyle(.primary)
				.lineLimit(1)
			
			Spacer()
			
			// Remove Button
			Button {
				onRemove()
			} label: {
				Image(systemName: "trash")
					.font(.system(size: 14))
					.foregroundStyle(.red)
			}
			.buttonStyle(.plain)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 10)
		.background(
			RoundedRectangle(cornerRadius: 8, style: .continuous)
				.fill(Color(UIColor.secondarySystemGroupedBackground))
		)
	}
	
	// MARK: - Data Loading
	private func loadData() {
		guard let path = Storage.shared.getAppDirectory(for: app) else { return }
		
		// Load dylibs
		let bundle = Bundle(url: path)
		let execPath = path.appendingPathComponent(bundle?.exec ?? "").relativePath
		let allDylibs = Zsign.listDylibs(appExecutable: execPath).map { $0 as String }
		dylibs = allDylibs.filter { $0.hasPrefix("@rpath") || $0.hasPrefix("@executable_path") }
		
		// Load frameworks
		frameworks = listFiles(at: path.appendingPathComponent("Frameworks"))
		
		// Load bundles (PlugIns)
		bundles = listFiles(at: path.appendingPathComponent("Plugins"))
	}
	
	private func listFiles(at path: URL) -> [String] {
		(try? FileManager.default.contentsOfDirectory(atPath: path.path)) ?? []
	}
	
	// MARK: - Actions
	private func enableAll() {
		withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
			// Remove all from removeFiles to enable all
			options.removeFiles.removeAll { item in
				frameworks.contains(where: { item.contains($0) }) ||
				bundles.contains(where: { item.contains($0) })
			}
		}
		HapticsManager.shared.success()
	}
	
	private func disableAll() {
		withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
			// Add all to removeFiles to disable all
			for framework in frameworks {
				let path = "Frameworks/\(framework)"
				if !options.removeFiles.contains(path) {
					options.removeFiles.append(path)
				}
			}
			for bundle in bundles {
				let path = "PlugIns/\(bundle)"
				if !options.removeFiles.contains(path) {
					options.removeFiles.append(path)
				}
			}
		}
		HapticsManager.shared.success()
	}
	
	private func expandAll() {
		withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
			expandedFrameworks = true
			expandedBundles = true
		}
		HapticsManager.shared.impact()
	}
	
	private func collapseAll() {
		withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
			expandedFrameworks = false
			expandedBundles = false
		}
		HapticsManager.shared.impact()
	}
	
	private func toggleFramework(_ framework: String) {
		let path = "Frameworks/\(framework)"
		withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
			if let index = options.removeFiles.firstIndex(of: path) {
				options.removeFiles.remove(at: index)
			} else {
				options.removeFiles.append(path)
			}
		}
		HapticsManager.shared.impact()
	}
	
	private func toggleBundle(_ bundle: String) {
		let path = "PlugIns/\(bundle)"
		withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
			if let index = options.removeFiles.firstIndex(of: path) {
				options.removeFiles.remove(at: index)
			} else {
				options.removeFiles.append(path)
			}
		}
		HapticsManager.shared.impact()
	}
	
	private func removeFramework(_ framework: String) {
		withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
			frameworks.removeAll { $0 == framework }
			// Also remove from options
			let path = "Frameworks/\(framework)"
			if let index = options.removeFiles.firstIndex(of: path) {
				options.removeFiles.remove(at: index)
			}
		}
		HapticsManager.shared.success()
	}
	
	private func removeBundle(_ bundle: String) {
		withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
			bundles.removeAll { $0 == bundle }
			// Also remove from options
			let path = "PlugIns/\(bundle)"
			if let index = options.removeFiles.firstIndex(of: path) {
				options.removeFiles.remove(at: index)
			}
		}
		HapticsManager.shared.success()
	}
}

// MARK: - Extract Tweaks View
struct ExtractTweaksView: View {
	@Environment(\.dismiss) var dismiss
	
	var app: AppInfoPresentable
	var frameworks: [String]
	var bundles: [String]
	
	@State private var selectedFrameworks = Set<String>()
	@State private var selectedBundles = Set<String>()
	@State private var isExtracting = false
	@State private var showSuccessAlert = false
	@State private var extractedZipURL: URL?
	
	var body: some View {
		NavigationView {
			ZStack {
				Color(UIColor.systemBackground)
					.ignoresSafeArea()
				
				VStack(spacing: 0) {
					if isExtracting {
						// Progress View
						VStack(spacing: 20) {
							ProgressView()
								.scaleEffect(1.5)
							
			Text("Extracting and creating zip file...")
								.font(.system(size: 16, weight: .medium))
								.foregroundStyle(.secondary)
						}
						.frame(maxWidth: .infinity, maxHeight: .infinity)
					} else {
						ScrollView {
							VStack(spacing: 24) {
								// Frameworks Section
								if !frameworks.isEmpty {
									extractSection(
										title: "Frameworks",
										items: frameworks,
										selectedItems: $selectedFrameworks,
										icon: "cube.fill",
										color: .blue
									)
								}
								
								// Bundles Section
								if !bundles.isEmpty {
									extractSection(
										title: "Bundles",
										items: bundles,
										selectedItems: $selectedBundles,
										icon: "shippingbox.fill",
										color: .purple
									)
								}
							}
							.padding(20)
							.padding(.bottom, 80)
						}
						
						// Extract Button
						VStack {
							Button {
								confirmExtract()
							} label: {
								HStack {
									Image(systemName: "arrow.down.circle.fill")
										.font(.system(size: 18))
									
									Text("Extract Selected Items")
										.font(.system(size: 16, weight: .semibold))
								}
								.foregroundStyle(.white)
								.frame(maxWidth: .infinity)
								.padding(.vertical, 16)
								.background(
									RoundedRectangle(cornerRadius: 14, style: .continuous)
										.fill(
											LinearGradient(
												colors: [Color.blue, Color.blue.opacity(0.8)],
												startPoint: .leading,
												endPoint: .trailing
											)
										)
								)
								.shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
							}
							.disabled(selectedFrameworks.isEmpty && selectedBundles.isEmpty)
							.opacity((selectedFrameworks.isEmpty && selectedBundles.isEmpty) ? 0.5 : 1.0)
							.padding(.horizontal, 20)
							.padding(.bottom, 20)
						}
						.background(
							Color(UIColor.systemBackground)
								.shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
						)
					}
				}
			}
			.navigationTitle("Extract Tweaks")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
				}
			}
			.alert("Success", isPresented: $showSuccessAlert) {
				Button("OK") {
					dismiss()
				}
			} message: {
				Text("Tweaks Extracted Successfully!")
			}
		}
	}
	
	@ViewBuilder
	private func extractSection(
		title: String,
		items: [String],
		selectedItems: Binding<Set<String>>,
		icon: String,
		color: Color
	) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			// Header with Select All
			HStack {
				HStack(spacing: 8) {
					Image(systemName: icon)
						.font(.system(size: 14))
						.foregroundStyle(color)
					
					Text(title.uppercased())
						.font(.system(size: 12, weight: .semibold))
						.foregroundStyle(Color(UIColor.secondaryLabel))
				}
				
				Spacer()
				
				Button {
					if selectedItems.wrappedValue.count == items.count {
						selectedItems.wrappedValue.removeAll()
					} else {
						selectedItems.wrappedValue = Set(items)
					}
				} label: {
					Text(selectedItems.wrappedValue.count == items.count ? "Deselect All" : "Select All")
						.font(.system(size: 13, weight: .medium))
						.foregroundStyle(color)
				}
			}
			.padding(.leading, 4)
			
			// Items List
			VStack(spacing: 8) {
				ForEach(items, id: \.self) { item in
					Button {
						if selectedItems.wrappedValue.contains(item) {
							selectedItems.wrappedValue.remove(item)
						} else {
							selectedItems.wrappedValue.insert(item)
						}
					} label: {
						HStack(spacing: 12) {
							// Checkbox
							ZStack {
								Circle()
									.stroke(
										selectedItems.wrappedValue.contains(item) ? color : Color.gray.opacity(0.3),
										lineWidth: 2
									)
									.frame(width: 24, height: 24)
								
								if selectedItems.wrappedValue.contains(item) {
									Image(systemName: "checkmark")
										.font(.system(size: 12, weight: .bold))
										.foregroundStyle(color)
								}
							}
							
							// Item name
							Text(item)
								.font(.system(size: 15, weight: .medium))
								.foregroundStyle(.primary)
								.lineLimit(1)
							
							Spacer()
						}
						.padding(12)
						.background(
							RoundedRectangle(cornerRadius: 10, style: .continuous)
								.fill(
									selectedItems.wrappedValue.contains(item) ?
									color.opacity(0.08) :
									Color(UIColor.secondarySystemGroupedBackground)
								)
						)
					}
					.buttonStyle(.plain)
				}
			}
		}
	}
	
	private func confirmExtract() {
		let totalItems = selectedFrameworks.count + selectedBundles.count
		
		UIAlertController.showAlert(
			title: "Confirm Extract",
			message: "Extract \(totalItems) selected item(s) into a zip file?",
			actions: [
				UIAlertAction(title: "Cancel", style: .cancel),
				UIAlertAction(title: "Extract", style: .default) { _ in
					performExtract()
				}
			]
		)
	}
	
	private func performExtract() {
		isExtracting = true
		
		Task {
			do {
				guard let appPath = Storage.shared.getAppDirectory(for: app) else {
					throw NSError(domain: "ExtractTweaks", code: -1, userInfo: [NSLocalizedDescriptionKey: "App Directory Not Found"])
				}
				
				// Create temporary directory for extraction
				let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
				try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
				
				// Copy selected frameworks
				if !selectedFrameworks.isEmpty {
					let frameworksDir = tempDir.appendingPathComponent("Frameworks")
					try FileManager.default.createDirectory(at: frameworksDir, withIntermediateDirectories: true)
					
					for framework in selectedFrameworks {
						let source = appPath.appendingPathComponent("Frameworks").appendingPathComponent(framework)
						let dest = frameworksDir.appendingPathComponent(framework)
						try FileManager.default.copyItem(at: source, to: dest)
					}
				}
				
				// Copy selected bundles
				if !selectedBundles.isEmpty {
					let bundlesDir = tempDir.appendingPathComponent("PlugIns")
					try FileManager.default.createDirectory(at: bundlesDir, withIntermediateDirectories: true)
					
					for bundle in selectedBundles {
						let source = appPath.appendingPathComponent("PlugIns").appendingPathComponent(bundle)
						let dest = bundlesDir.appendingPathComponent(bundle)
						try FileManager.default.copyItem(at: source, to: dest)
					}
				}
				
				// Create zip file in Documents directory
				let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
				let zipFileName = "ExtractedTweaks_\(Date().timeIntervalSince1970).zip"
				let zipURL = documentsDir.appendingPathComponent(zipFileName)
				
				// Remove existing zip if present
				try? FileManager.default.removeItem(at: zipURL)
				
				// Create zip
				try Zip.zipFiles(paths: [tempDir], zipFilePath: zipURL, password: nil, progress: nil)
				
				// Clean up temp directory
				try? FileManager.default.removeItem(at: tempDir)
				
				await MainActor.run {
					isExtracting = false
					extractedZipURL = zipURL
					showSuccessAlert = true
					HapticsManager.shared.success()
				}
			} catch {
				await MainActor.run {
					isExtracting = false
					HapticsManager.shared.error()
					
					UIAlertController.showAlertWithOk(
						title: "Error",
						message: "Failed to extract tweaks: \(error.localizedDescription)"
					)
				}
			}
		}
	}
}
