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
            } header: {
                AppearanceSectionHeader(title: "Style", icon: "paintbrush.fill")
            } footer: {
                Text("Minimal is the new modern list style. Card and Flat provide classic bordered looks.")
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
            } header: {
                AppearanceSectionHeader(title: "Layout & Icons", icon: "square.grid.2x2.fill")
            } footer: {
                Text("Personalize the look and feel of your app list.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("All Apps")
    }
}
