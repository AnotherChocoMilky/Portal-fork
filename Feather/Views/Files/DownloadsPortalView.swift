import SwiftUI
import NimbleViews

// MARK: - Downloads Portal Models
struct DownloadsPortalItem: Codable, Identifiable {
    let name: String
    let description: String?
    let url: String
    let icon: String?
    let category: String?
    let version: String?
    let size: String?
    
    var id: String { url + name }
    
    enum CodingKeys: String, CodingKey {
        case name, description, url, icon, category, version, size
        case downloadURL // Map from JSON
        case note // Map to description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)

        // Handle url or downloadURL
        if let dURL = try? container.decode(String.self, forKey: .downloadURL) {
            url = dURL
        } else {
            url = try container.decode(String.self, forKey: .url)
        }

        // Handle description or note
        if let note = try? container.decodeIfPresent(String.self, forKey: .note) {
            description = note
        } else {
            description = try? container.decodeIfPresent(String.self, forKey: .description)
        }

        icon = try? container.decodeIfPresent(String.self, forKey: .icon)
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        version = try? container.decodeIfPresent(String.self, forKey: .version)
        size = try? container.decodeIfPresent(String.self, forKey: .size)
    }

    // Custom initializer for flattened apps
    init(name: String, url: String, description: String?, icon: String?, category: String?) {
        self.name = name
        self.url = url
        self.description = description
        self.icon = icon
        self.category = category
        self.version = nil
        self.size = nil
    }
}

extension DownloadsPortalItem: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(size, forKey: .size)
    }
}

// Intermediate models for complex JSON
struct DownloadsPortalApp: Codable {
    let name: String
    let image: String?
    let certs: [DownloadsPortalCert]?
}

struct DownloadsPortalCert: Codable {
    let certName: String
    let downloadURL: String
}

struct DownloadsPortalResponse: Codable {
    var downloads: [DownloadsPortalItem] = []
    
    enum CodingKeys: String, CodingKey {
        case downloads, items, files, data, apps
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var allItems: [DownloadsPortalItem] = []

        // Try "files" key (WSF structure)
        if let files = try? container.decode([DownloadsPortalItem].self, forKey: .files) {
            allItems.append(contentsOf: files)
        }

        // Try "apps" key (WSF structure)
        if let apps = try? container.decode([DownloadsPortalApp].self, forKey: .apps) {
            for app in apps {
                if let certs = app.certs {
                    for cert in certs {
                        allItems.append(DownloadsPortalItem(
                            name: "\(app.name) - \(cert.certName)",
                            url: cert.downloadURL,
                            description: "App from Downloads Portal",
                            icon: "app.badge.fill",
                            category: "App"
                        ))
                    }
                }
            }
        }
        
        // Try other standard keys
        if let items = try? container.decode([DownloadsPortalItem].self, forKey: .downloads) {
            allItems.append(contentsOf: items)
        } else if let items = try? container.decode([DownloadsPortalItem].self, forKey: .items) {
            allItems.append(contentsOf: items)
        } else if let items = try? container.decode([DownloadsPortalItem].self, forKey: .data) {
            allItems.append(contentsOf: items)
        }
        
        // If still empty, try decoding the entire JSON as an array
        if allItems.isEmpty {
            let singleContainer = try decoder.singleValueContainer()
            if let items = try? singleContainer.decode([DownloadsPortalItem].self) {
                allItems.append(contentsOf: items)
            }
        }

        self.downloads = allItems
    }
}

extension DownloadsPortalResponse: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(downloads, forKey: .downloads)
    }
}

// MARK: - Downloads Portal Service
class DownloadsPortalService: ObservableObject {
    @Published var items: [DownloadsPortalItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var rawJSONResponse: String?
    
    private let githubURL = "https://raw.githubusercontent.com/WhySooooFurious/Ultimate-Sideloading-Guide/refs/heads/main/raw-files/downloads.json"
    
    func fetchDownloads() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        AppLogManager.shared.info("Starting Downloads Portal fetch from: \(githubURL)", category: "Downloads")
        
        do {
            guard let url = URL(string: githubURL) else {
                throw NSError(domain: "DownloadsPortal", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Log raw JSON for debugging
            let jsonString = String(data: data, encoding: .utf8) ?? "Unable to decode"
            await MainActor.run {
                self.rawJSONResponse = jsonString
            }
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(DownloadsPortalResponse.self, from: data)
            
            await MainActor.run {
                self.items = decodedResponse.downloads
                self.isLoading = false
            }
            
            AppLogManager.shared.success("Successfully loaded \(decodedResponse.downloads.count) items", category: "Downloads")
            
        } catch {
            AppLogManager.shared.error("Fetch Error: \(error.localizedDescription)", category: "Downloads")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Downloads Portal View
struct DownloadsPortalView: View {
    @StateObject private var service = DownloadsPortalService()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NBNavigationView(.localized("Downloads Portal"), displayMode: .inline) {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.1),
                        Color.accentColor.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if service.isLoading {
                    loadingView
                } else if let error = service.errorMessage {
                    errorView(error: error)
                } else if service.items.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) {
                        dismiss()
                    }
                }
            })
            .task {
                await service.fetchDownloads()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(.localized("Loading Downloads..."))
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text(.localized("Error Loading Downloads"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Task {
                    await service.fetchDownloads()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text(.localized("Retry"))
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(Capsule())
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(.localized("No Downloads Available"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(.localized("Check back later for available downloads"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.15),
                                        Color.accentColor.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text(.localized("Downloads Portal"))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(.localized("Browse and download files from the WSF portal"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Download items
                ForEach(service.items) { item in
                    DownloadItemCard(item: item)
                }
            }
            .padding()
        }
    }
}

// MARK: - Download Item Card
struct DownloadItemCard: View {
    let item: DownloadsPortalItem
    @State private var isDownloading = false
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.15),
                                    Color.accentColor.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: item.icon ?? "doc.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let description = item.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    if let category = item.category {
                        Text(category)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
            }
            
            // Download button
            Button {
                downloadFile()
            } label: {
                HStack(spacing: 8) {
                    if isDownloading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.body)
                    }
                    Text(isDownloading ? .localized("Downloading...") : .localized("Download"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(isDownloading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private func downloadFile() {
        guard let url = URL(string: item.url) else { return }
        
        isDownloading = true
        HapticsManager.shared.impact()
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let fileName = URL(string: item.url)?.lastPathComponent ?? "download"
                let destinationURL = FileManagerService.shared.currentDirectory.appendingPathComponent(fileName)
                
                try data.write(to: destinationURL)
                
                await MainActor.run {
                    isDownloading = false
                    HapticsManager.shared.success()
                    FileManagerService.shared.loadFiles()
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    HapticsManager.shared.error()
                    AppLogManager.shared.error("Failed to download file: \(error.localizedDescription)", category: "Files")
                }
            }
        }
    }
}
