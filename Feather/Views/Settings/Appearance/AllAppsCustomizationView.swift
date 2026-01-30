import SwiftUI

struct AllAppsCustomizationView: View {
    @AppStorage("Feather.allApps.showVersion") private var showVersion: Bool = true
    @AppStorage("Feather.allApps.showSize") private var showSize: Bool = true
    @AppStorage("Feather.allApps.showDeveloper") private var showDeveloper: Bool = true
    @AppStorage("Feather.allApps.showStatus") private var showStatus: Bool = true
    @AppStorage("Feather.allApps.showSourceIcon") private var showSourceIcon: Bool = true
    @AppStorage("Feather.allApps.showSorting") private var showSorting: Bool = true

    @AppStorage("Feather.allApps.iconSize") private var iconSize: Double = 54.0
    @AppStorage("Feather.allApps.iconCornerRadius") private var iconCornerRadius: Double = 12.0
    @AppStorage("Feather.allApps.iconPadding") private var iconPadding: Double = 0
    @AppStorage("Feather.allApps.rowSpacing") private var rowSpacing: Double = 0
    @AppStorage("Feather.allApps.rowStyle") private var rowStyle: AllAppsView.AllAppsRowStyle = .minimal

    // Advanced Customization
    @AppStorage("Feather.allApps.useGrid") private var useGrid: Bool = false
    @AppStorage("Feather.allApps.gridColumns") private var gridColumns: Int = 3
    @AppStorage("Feather.allApps.titleFontSize") private var titleFontSize: Double = 17.0
    @AppStorage("Feather.allApps.subtitleFontSize") private var subtitleFontSize: Double = 13.0
    @AppStorage("Feather.allApps.boldTitles") private var boldTitles: Bool = true
    @AppStorage("Feather.allApps.useGlassEffects") private var useGlassEffects: Bool = true
    @AppStorage("Feather.allApps.showDescription") private var showDescription: Bool = false
    @AppStorage("Feather.allApps.descriptionLimit") private var descriptionLimit: Int = 2
    @AppStorage("Feather.allApps.searchBarFloating") private var searchBarFloating: Bool = false
    @AppStorage("Feather.allApps.rowDividerOpacity") private var rowDividerOpacity: Double = 0.5
    @AppStorage("Feather.allApps.showAppCount") private var showAppCount: Bool = true

    var body: some View {
        List {
            Section {
                Picker(selection: $rowStyle) {
                    ForEach(AllAppsView.AllAppsRowStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                } label: {
                    AppearanceRowLabel(icon: "rectangle.grid.1x2.fill", title: "Row Style", color: .blue)
                }
                .pickerStyle(.menu)
                .disabled(useGrid)

                Toggle(isOn: $useGrid) {
                    AppearanceRowLabel(icon: "square.grid.3x3.fill", title: "Use Grid Layout", color: .pink)
                }
            } header: {
                AppearanceSectionHeader(title: "Style", icon: "paintbrush.fill")
            } footer: {
                Text(useGrid ? "Grid layout overrides row style settings." : "Minimal is the new modern list style. Card and Flat provide classic bordered looks.")
            }

            if useGrid {
                Section {
                    Stepper(value: $gridColumns, in: 2...4) {
                        AppearanceRowLabel(icon: "columns.2", title: "Grid Columns: \(gridColumns)", color: .pink)
                    }
                } header: {
                    AppearanceSectionHeader(title: "Grid Settings", icon: "square.grid.2x2.fill")
                }
            }

            Section {
                Toggle(isOn: $showVersion) {
                    AppearanceRowLabel(icon: "tag.fill", title: "Show Version Number", color: .blue)
                }
                Toggle(isOn: $showSize) {
                    AppearanceRowLabel(icon: "internaldrive.fill", title: "Show App Size", color: .green)
                }
                Toggle(isOn: $showDeveloper) {
                    AppearanceRowLabel(icon: "person.2.fill", title: "Show Developer Name", color: .orange)
                }
                Toggle(isOn: $showStatus) {
                    AppearanceRowLabel(icon: "checkmark.seal.fill", title: "Show App Status", color: .cyan)
                }
                Toggle(isOn: $showSourceIcon) {
                    AppearanceRowLabel(icon: "archivebox.fill", title: "Show Source Icon", color: .green)
                }
                Toggle(isOn: $showSorting) {
                    AppearanceRowLabel(icon: "line.3.horizontal.decrease.circle.fill", title: "Show Sorting Options", color: .purple)
                }
                Toggle(isOn: $showDescription) {
                    AppearanceRowLabel(icon: "text.alignleft", title: "Show App Description", color: .indigo)
                }

                if showDescription {
                    Stepper(value: $descriptionLimit, in: 1...5) {
                        AppearanceRowLabel(icon: "line.3.horizontal", title: "Description Lines: \(descriptionLimit)", color: .indigo)
                    }
                }
            } header: {
                AppearanceSectionHeader(title: "Metadata", icon: "info.circle.fill")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "app.fill", title: "Icon Size: \(Int(iconSize))", color: .blue)
                    Slider(value: $iconSize, in: 40...80, step: 2)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "squareshape.fill", title: "Icon Radius: \(Int(iconCornerRadius))", color: .green)
                    Slider(value: $iconCornerRadius, in: 0...30, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "arrow.left.and.right", title: "Icon Left Gap: \(Int(iconPadding))", color: .orange)
                    Slider(value: $iconPadding, in: 0...40, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "arrow.up.and.down", title: "Row Spacing: \(Int(rowSpacing))", color: .purple)
                    Slider(value: $rowSpacing, in: 0...30, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "line.horizontal.3", title: "Divider Opacity: \(String(format: "%.1f", rowDividerOpacity))", color: .gray)
                    Slider(value: $rowDividerOpacity, in: 0...1, step: 0.1)
                }
                .padding(.vertical, 4)
            } header: {
                AppearanceSectionHeader(title: "Layout & Icons", icon: "square.grid.2x2.fill")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "textformat.size", title: "Title Font Size: \(Int(titleFontSize))", color: .blue)
                    Slider(value: $titleFontSize, in: 12...24, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "textformat.size.smaller", title: "Subtitle Font Size: \(Int(subtitleFontSize))", color: .green)
                    Slider(value: $subtitleFontSize, in: 10...18, step: 1)
                }
                .padding(.vertical, 4)

                Toggle(isOn: $boldTitles) {
                    AppearanceRowLabel(icon: "bold", title: "Bold Titles", color: .primary)
                }
            } header: {
                AppearanceSectionHeader(title: "Typography", icon: "textformat")
            }

            Section {
                Toggle(isOn: $searchBarFloating) {
                    AppearanceRowLabel(icon: "magnifyingglass.circle.fill", title: "Floating Search Bar", color: .blue)
                }

                Toggle(isOn: $useGlassEffects) {
                    AppearanceRowLabel(icon: "drop.fill", title: "Glass Effects", color: .cyan)
                }

                Toggle(isOn: $showAppCount) {
                    AppearanceRowLabel(icon: "number.circle.fill", title: "Show App Count Header", color: .orange)
                }
            } header: {
                AppearanceSectionHeader(title: "UI Effects", icon: "sparkles")
            } footer: {
                Text("Personalize the look and feel of your app list.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("All Apps")
    }
}
