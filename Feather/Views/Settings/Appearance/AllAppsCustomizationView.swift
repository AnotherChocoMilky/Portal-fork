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
    @AppStorage("Feather.allApps.iconShadowRadius") private var iconShadowRadius: Double = 0.0
    @AppStorage("Feather.allApps.rowSpacing") private var rowSpacing: Double = 0
    @AppStorage("Feather.allApps.rowStyle") private var rowStyle: AllAppsView.AllAppsRowStyle = .minimal
    @AppStorage("Feather.allApps.rowHorizontalPadding") private var rowHorizontalPadding: Double = 20.0
    @AppStorage("Feather.allApps.infoSpacing") private var infoSpacing: Double = 14.0
    @AppStorage("Feather.allApps.showDividers") private var showDividers: Bool = true
    @AppStorage("Feather.allApps.dividerOpacity") private var dividerOpacity: Double = 0.5
    @AppStorage("Feather.allApps.useSpringAnimations") private var useSpringAnimations: Bool = true

    @AppStorage("Feather.allApps.nameFontSize") private var nameFontSize: Double = 17.0
    @AppStorage("Feather.allApps.subtitleFontSize") private var subtitleFontSize: Double = 13.0
    @AppStorage("Feather.allApps.metadataFontSize") private var metadataFontSize: Double = 12.0
    @AppStorage("Feather.allApps.useBoldTitles") private var useBoldTitles: Bool = true

    // Advanced Customization
    @AppStorage("Feather.allApps.useGrid") private var useGrid: Bool = false
    @AppStorage("Feather.allApps.gridColumns") private var gridColumns: Int = 3
    @AppStorage("Feather.allApps.titleFontSize") private var titleFontSize: Double = 17.0
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

                Toggle(isOn: $useSpringAnimations) {
                    AppearanceRowLabel(icon: "sparkles", title: "Spring Animations", color: .orange)
                }
            } header: {
                AppearanceSectionHeader(title: "Style & Feel", icon: "paintbrush.fill")
            } footer: {
                Text("Minimal is modern. Spring animations add responsiveness.")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "textformat.size", title: "App Name Size: \(Int(nameFontSize))", color: .blue)
                    Slider(value: $nameFontSize, in: 14...24, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "textformat.size", title: "Subtitle Size: \(Int(subtitleFontSize))", color: .cyan)
                    Slider(value: $subtitleFontSize, in: 10...18, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "textformat.size", title: "Metadata Size: \(Int(metadataFontSize))", color: .green)
                    Slider(value: $metadataFontSize, in: 8...16, step: 1)
                }
                .padding(.vertical, 4)

                Toggle(isOn: $useBoldTitles) {
                    AppearanceRowLabel(icon: "bold", title: "Bold App Names", color: .purple)
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
                AppearanceSectionHeader(title: "Typography", icon: "textformat")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "app.fill", title: "Icon Size: \(Int(iconSize))", color: .blue)
                    Slider(value: $iconSize, in: 30...90, step: 2)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "squareshape.fill", title: "Icon Radius: \(Int(iconCornerRadius))", color: .green)
                    Slider(value: $iconCornerRadius, in: 0...40, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "sun.max.fill", title: "Icon Shadow: \(Int(iconShadowRadius))", color: .yellow)
                    Slider(value: $iconShadowRadius, in: 0...20, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "arrow.left.and.right", title: "Icon Left Gap: \(Int(iconPadding))", color: .orange)
                    Slider(value: $iconPadding, in: 0...60, step: 1)
                }
                .padding(.vertical, 4)
            } header: {
                AppearanceSectionHeader(title: "Icon Styling", icon: "square.grid.2x2.fill")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "arrow.up.and.down", title: "Row Vertical Spacing: \(Int(rowSpacing))", color: .purple)
                    Slider(value: $rowSpacing, in: 0...40, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "arrow.left.and.right", title: "Row Side Padding: \(Int(rowHorizontalPadding))", color: .pink)
                    Slider(value: $rowHorizontalPadding, in: 0...40, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    AppearanceRowLabel(icon: "arrow.left.and.right.text.vertical", title: "Info Spacing: \(Int(infoSpacing))", color: .cyan)
                    Slider(value: $infoSpacing, in: 0...40, step: 1)
                }
                .padding(.vertical, 4)
            } header: {
                AppearanceSectionHeader(title: "Row Layout", icon: "square.stack.3d.up.fill")
            }

            Section {
                Toggle(isOn: $showVersion) {
                    AppearanceRowLabel(icon: "tag.fill", title: "Show Version", color: .blue)
                }
                Toggle(isOn: $showSize) {
                    AppearanceRowLabel(icon: "internaldrive.fill", title: "Show Size", color: .green)
                }
                Toggle(isOn: $showDeveloper) {
                    AppearanceRowLabel(icon: "person.2.fill", title: "Show Developer", color: .orange)
                }
                Toggle(isOn: $showStatus) {
                    AppearanceRowLabel(icon: "checkmark.seal.fill", title: "Show Status", color: .cyan)
                }
                Toggle(isOn: $showSourceIcon) {
                    AppearanceRowLabel(icon: "archivebox.fill", title: "Show Source", color: .green)
                }
                Toggle(isOn: $showSorting) {
                    AppearanceRowLabel(icon: "line.3.horizontal.decrease.circle.fill", title: "Show Sorting", color: .purple)
                }
            } header: {
                AppearanceSectionHeader(title: "Metadata Visibility", icon: "info.circle.fill")
            }

            Section {
                Toggle(isOn: $showDividers) {
                    AppearanceRowLabel(icon: "minus", title: "Show Dividers", color: .gray)
                }

                if showDividers {
                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "opacity", title: "Divider Opacity: \(Int(dividerOpacity * 100))%", color: .gray)
                        Slider(value: $dividerOpacity, in: 0...1, step: 0.05)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                AppearanceSectionHeader(title: "Dividers", icon: "square.split.1x2.fill")
            } footer: {
                Text("Customize every detail of the app list to match your preference.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("All Apps")
    }
}
