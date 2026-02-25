import SwiftUI
import NimbleViews

struct RepoMeta: Codable {
    var repoName: String
    var iconURL: String
}

struct RepoApp: Codable, Identifiable {
    var id = UUID()
    var name: String = ""
    var bundleIdentifier: String = ""
    var developerName: String = ""
    var news: String = ""
    var size: String = ""
    var version: String = ""
    var localizedDescription: String = ""
    var versionDate: String = ""
    var iconURL: String = ""
    var downloadURL: String = ""
    var type: Int = 1

    enum CodingKeys: String, CodingKey {
        case name
        case bundleIdentifier
        case developerName
        case news
        case size
        case version
        case localizedDescription
        case versionDate
        case iconURL
        case downloadURL
        case type
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
        try container.encode(developerName, forKey: .developerName)
        try container.encode(news, forKey: .news)
        try container.encode(Int(size) ?? 0, forKey: .size)
        try container.encode(version, forKey: .version)
        try container.encode(localizedDescription, forKey: .localizedDescription)
        try container.encode(versionDate, forKey: .versionDate)
        try container.encode(iconURL, forKey: .iconURL)
        try container.encode(downloadURL, forKey: .downloadURL)
        try container.encode(type, forKey: .type)
    }
}

struct RepoSource: Codable {
    var name: String
    var identifier: String
    var sourceURL: String
    var iconURL: String
    var website: String = ""
    var subtitle: String = ""
    var apps: [RepoApp]

    enum CodingKeys: String, CodingKey {
        case name, identifier, sourceURL, iconURL, website, subtitle, apps, META
    }

    init(name: String, identifier: String, sourceURL: String, iconURL: String, website: String = "", subtitle: String = "", apps: [RepoApp]) {
        self.name = name
        self.identifier = identifier
        self.sourceURL = sourceURL
        self.iconURL = iconURL
        self.website = website
        self.subtitle = subtitle
        self.apps = apps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        identifier = try container.decode(String.self, forKey: .identifier)
        sourceURL = try container.decode(String.self, forKey: .sourceURL)
        iconURL = try container.decode(String.self, forKey: .iconURL)
        website = (try? container.decode(String.self, forKey: .website)) ?? ""
        subtitle = (try? container.decode(String.self, forKey: .subtitle)) ?? ""
        apps = try container.decode([RepoApp].self, forKey: .apps)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(sourceURL, forKey: .sourceURL)
        try container.encode(iconURL, forKey: .iconURL)
        if !website.isEmpty { try container.encode(website, forKey: .website) }
        if !subtitle.isEmpty { try container.encode(subtitle, forKey: .subtitle) }
        try container.encode(apps, forKey: .apps)
        try container.encode(RepoMeta(repoName: name, iconURL: iconURL), forKey: .META)
    }
}

struct RepoBuilder: View {
    @State private var repoName = ""
    @State private var repoIdentifier = ""
    @State private var sourceURL = ""
    @State private var iconURL = ""
    @State private var website = ""
    @State private var subtitle = ""
    @State private var apps: [RepoApp] = []

    @State private var showingAddApp = false
    @State private var showingGuide = false

    var body: some View {
        NBNavigationView(String.localized("Repository Builder")) {
            Form {
                Section(header: Text(String.localized("Source Information"))) {
                    TextField(String.localized("Source Name"), text: $repoName)
                    TextField(String.localized("Source Identifier"), text: $repoIdentifier)
                    TextField(String.localized("Source URL"), text: $sourceURL)
                    TextField(String.localized("Icon URL"), text: $iconURL)
                    TextField(String.localized("Website (Optional)"), text: $website)
                    TextField(String.localized("Subtitle (Optional)"), text: $subtitle)
                }

                Section(header: Text(String.localized("Apps (\(apps.count))"))) {
                    ForEach(apps) { app in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.name)
                                .font(.headline)
                            Text(app.bundleIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indices in
                        apps.remove(atOffsets: indices)
                    }

                    Button {
                        showingAddApp = true
                    } label: {
                        Label(String.localized("Add App"), systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    Button(action: generateSource) {
                        Text(String.localized("Generate Source"))
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingGuide = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddApp) {
                AddRepoAppView { newApp in
                    apps.append(newApp)
                }
            }
            .sheet(isPresented: $showingGuide) {
                RepoBuilderGuideView()
            }
        }
    }

    private func generateSource() {
        let source = RepoSource(
            name: repoName,
            identifier: repoIdentifier,
            sourceURL: sourceURL,
            iconURL: iconURL,
            website: website,
            subtitle: subtitle,
            apps: apps
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(source)
            if let jsonString = String(data: data, encoding: .utf8) {
                UIPasteboard.general.string = jsonString
                ToastManager.shared.show(String.localized("Source JSON copied to clipboard!"), type: .success)
                HapticsManager.shared.success()
            }
        } catch {
            ToastManager.shared.show(String.localized("Failed to generate JSON"), type: .error)
        }
    }
}

struct AddRepoAppView: View {
    @Environment(\.dismiss) var dismiss
    @State private var app = RepoApp()
    var onAdd: (RepoApp) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(String.localized("App Details"))) {
                    TextField(String.localized("App Name"), text: $app.name)
                    TextField(String.localized("Bundle ID"), text: $app.bundleIdentifier)
                    TextField(String.localized("Developer Name"), text: $app.developerName)
                    TextField(String.localized("Version"), text: $app.version)
                    TextField(String.localized("Version Date (YYYY-MM-DD)"), text: $app.versionDate)
                    TextField(String.localized("Size (Bytes)"), text: $app.size)
                        .keyboardType(.numberPad)
                    Stepper(value: $app.type, in: 1...10) {
                        HStack {
                            Text(String.localized("Type"))
                            Spacer()
                            Text("\(app.type)")
                        }
                    }
                }

                Section(header: Text(String.localized("Content"))) {
                    TextField(String.localized("Icon URL"), text: $app.iconURL)
                    TextField(String.localized("Download URL (.ipa)"), text: $app.downloadURL)
                    TextField(String.localized("News"), text: $app.news)

                    VStack(alignment: .leading) {
                        Text(String.localized("Localized Description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $app.localizedDescription)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(String.localized("Add App"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String.localized("Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String.localized("Add")) {
                        onAdd(app)
                        dismiss()
                    }
                    .disabled(app.name.isEmpty || app.bundleIdentifier.isEmpty)
                }
            }
        }
    }
}

struct RepoBuilderGuideView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    guideSection(
                        title: String.localized("What is each slot for?"),
                        content: [
                            String.localized("• Source Name: The display name of your repository."),
                            String.localized("• Source Identifier: A unique ID (e.g., com.example.repo)."),
                            String.localized("• Source URL: The direct URL to your JSON file."),
                            String.localized("• Icon URL: A link to a square image (PNG/JPG)."),
                            String.localized("• Website/Subtitle: Optional metadata for your repository."),
                            String.localized("• App Name: The name of the application."),
                            String.localized("• Bundle ID: The unique identifier of the app (e.g., com.apple.Stocks)."),
                            String.localized("• News: What's new in this specific version."),
                            String.localized("• Size: The size of the IPA file in bytes."),
                            String.localized("• Version Date: The release date of the version."),
                            String.localized("• Type: The app type (usually 1 for normal apps).")
                        ]
                    )

                    guideSection(
                        title: String.localized("How to host the repository?"),
                        content: [
                            String.localized("1. Generate the JSON using this tool."),
                            String.localized("2. Create a new repository on GitHub."),
                            String.localized("3. Upload the generated JSON (e.g., as 'repo.json')."),
                            String.localized("4. Click on the file, then click 'Raw' to get the direct link."),
                            String.localized("5. This Raw link is what users will add as a Source.")
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle(String.localized("Guide"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String.localized("Done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func guideSection(title: String, content: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .bold()

            ForEach(content, id: \.self) { line in
                Text(line)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
