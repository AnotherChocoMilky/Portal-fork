import SwiftUI
import CoreData
import NimbleViews
import Combine
import IDeviceSwift

// MARK: - Modern Library View with Blue Gradient Background
struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("Feather.useGradients") private var _useGradients: Bool = true
    
    @StateObject var downloadManager = DownloadManager.shared
    @StateObject private var hideManager = LibraryHideManager.shared
    
    @State private var _selectedInfoAppPresenting: AnyApp?
    @State private var _selectedSigningAppPresenting: AnyApp?
    @State private var _selectedInstallAppPresenting: AnyApp?
    @State private var _selectedInstallModifyAppPresenting: AnyApp?
    @State private var _isImportingPresenting = false
    @State private var _isDownloadingPresenting = false
    @State private var _showImportAnimation = false
    @State private var _importStatus: ImportStatus = .loading
    @State private var _importedAppName: String = ""
    @State private var _importErrorMessage: String = ""
    @State private var _currentDownloadId: String = ""
    @State private var _downloadProgress: Double = 0.0
    @State private var _shouldAutoSignNext = false
    
    // Batch selection states
    @State private var _editMode: EditMode = .inactive
    @State private var _selectedApps: Set<String?> = []
    @State private var _showBatchSigningSheet = false
    @State private var _showBatchDeleteConfirmation = false
    
    enum ImportStatus {
        case loading
        case downloading
        case processing
        case success
        case failed
    }
    
    @State private var _searchText = ""
    @State private var _filterMode: FilterMode = .all
    
    enum FilterMode: String, CaseIterable {
        case all = "All"
        case unsigned = "Imported"
        case signed = "Signed"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .unsigned: return "doc.badge.clock"
            case .signed: return "checkmark.seal"
            }
        }
    }
    
    @Namespace private var _namespace
    
    @FetchRequest(
        entity: Signed.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
        animation: .default
    ) private var _signedApps: FetchedResults<Signed>
    
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
        animation: .default
    ) private var _importedApps: FetchedResults<Imported>
    
    private var filteredSignedApps: [Signed] {
        _signedApps.filter { app in
            _searchText.isEmpty || (app.name?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    private var filteredImportedApps: [Imported] {
        _importedApps.filter { app in
            _searchText.isEmpty || (app.name?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    private var displayedApps: [AppInfoPresentable] {
        switch _filterMode {
        case .all:
            return Array(filteredSignedApps) + Array(filteredImportedApps)
        case .unsigned:
            return Array(filteredImportedApps)
        case .signed:
            return Array(filteredSignedApps)
        }
    }
    
    private var totalAppCount: Int {
        _signedApps.count + _importedApps.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LibraryDownloadHeaderView(downloadManager: downloadManager)
                    .padding(.top, 10)
                
                if !hideManager.isHidden("library.filterChips") {
                    filterChips
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }

                List(selection: $_selectedApps) {
                    if displayedApps.isEmpty {
                        Section {
                            emptyStateView
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    } else {
                        ForEach(displayedApps, id: \.uuid) { app in
                            LibraryAppRow(
                                app: app,
                                selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                                selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                                selectedInstallAppPresenting: $_selectedInstallAppPresenting
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Storage.shared.deleteApp(for: app)
                                } label: {
                                    Label(String.localized("Delete"), systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            .contextMenu {
                                Button {
                                    _selectedInfoAppPresenting = AnyApp(base: app)
                                } label: {
                                    Label(String.localized("Details"), systemImage: "info.circle")
                                }

                                if app.isSigned {
                                    Button {
                                        _selectedInstallAppPresenting = AnyApp(base: app)
                                    } label: {
                                        Label(String.localized("Install"), systemImage: "arrow.down.circle")
                                    }
                                    Button {
                                        _selectedSigningAppPresenting = AnyApp(base: app)
                                    } label: {
                                        Label(String.localized("Sign Again"), systemImage: "signature")
                                    }
                                } else {
                                    Button {
                                        _selectedSigningAppPresenting = AnyApp(base: app)
                                    } label: {
                                        Label(String.localized("Sign"), systemImage: "signature")
                                    }
                                }

                                Divider()

                                Button(role: .destructive) {
                                    Storage.shared.deleteApp(for: app)
                                } label: {
                                    Label(String.localized("Delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, $_editMode)

                if _editMode == .active && !_selectedApps.isEmpty {
                    selectionActionBar
                        .padding(.horizontal, 20)
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Library")
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    if !hideManager.isHidden("library.importButton") {
                        Menu {
                            _importActions()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.accentColor)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
            })
                        .sheet(item: $_selectedInfoAppPresenting) { app in
                                LibraryInfoView(app: app.base)
                        }
                        .sheet(item: $_selectedInstallAppPresenting) { app in
                                InstallPreviewView(app: app.base, isSharing: app.archive)
                                        .presentationDetents([.height(200)])
                                        .presentationDragIndicator(.visible)
                                        .compatPresentationRadius(21)
                        }
                        .fullScreenCover(item: $_selectedSigningAppPresenting) { app in
                                ModernSigningView(app: app.base)
                        }
                        .sheet(item: $_selectedInstallModifyAppPresenting) { app in
                                InstallModifyDialogView(app: app.base)
                                        .presentationDetents([.medium, .large])
                                        .presentationDragIndicator(.visible)
                        }
                        .sheet(isPresented: $_isImportingPresenting) {
                                FileImporterRepresentableView(
                                        allowedContentTypes:  [.ipa, .tipa],
                                        allowsMultipleSelection: true,
                                        onDocumentsPicked: { urls in
                                                guard !urls.isEmpty else { return }
                                                
                                                for url in urls {
                                                        let id = "FeatherManualDownload_\(UUID().uuidString)"
                                                        let dl = downloadManager.startArchive(from: url, id: id)
                                                        
                                                    
                                                        _importedAppName = url.deletingPathExtension().lastPathComponent
                                                        _currentDownloadId = id
                                                        _importStatus = .processing
                                                        _importErrorMessage = ""
                                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                                                _showImportAnimation = true
                                                        }
                                                        
                                                        // Start the import - completion will be handled via notifications
                                                        do {
                                                                try downloadManager.handlePachageFile(url: url, dl: dl)
                                                        } catch {
                                                                // This catch is for synchronous errors only (rare)
                                                                _importErrorMessage = error.localizedDescription
                                                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                                                        _importStatus = .failed
                                                                }
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                                                        withAnimation(.easeOut(duration: 0.3)) {
                                                                                _showImportAnimation = false
                                                                        }
                                                                }
                                                        }
                                                }
                                        }
                                )
                                .ignoresSafeArea()
                        }
                        .sheet(isPresented: $_isDownloadingPresenting) {
                                ModernImportURLView { url in
                                        // Start URL download with proper tracking
                                        let downloadId = "FeatherManualDownload_\(UUID().uuidString)"
                                        _currentDownloadId = downloadId
                                        _importedAppName = url.deletingPathExtension().lastPathComponent
                                        _downloadProgress = 0.0
                                        _importStatus = .downloading
                                        _importErrorMessage = ""
                                        
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                                _showImportAnimation = true
                                        }
                                        
                                        // Start the download - progress and completion handled via notifications
                                        _ = downloadManager.startDownload(from: url, id: downloadId)
                                }
                                .presentationDetents([.medium, .large])
                                .presentationDragIndicator(.visible)
                        }
            .fullScreenCover(isPresented: $_showBatchSigningSheet) {
                BatchSigningView(
                    apps: getSelectedUnsignedApps(),
                    onComplete: {
                        _showBatchSigningSheet = false
                        _selectedApps.removeAll()
                        _editMode = .inactive
                    }
                )
            }
            .alert("Delete Selected Apps", isPresented: $_showBatchDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSelectedApps()
                }
            } message: {
                Text("Are you sure you want to delete \(_selectedApps.count) selected app(s)?")
            }
                        // Listen for import success notifications
                        .onReceive(NotificationCenter.default.publisher(for: DownloadManager.importDidSucceedNotification)) { notification in
                                guard let userInfo = notification.userInfo,
                                          let downloadId = userInfo["downloadId"] as? String,
                                          downloadId == _currentDownloadId else { return }
                                
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        _importStatus = .success
                                }
                                
                                // Auto-sign logic
                                if _shouldAutoSignNext {
                                    _shouldAutoSignNext = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        if let latestApp = Storage.shared.getLatestImportedApp() {
                                            _selectedSigningAppPresenting = AnyApp(base: latestApp)
                                        }
                                    }
                                }

                                // Auto-dismiss after showing success
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                                _showImportAnimation = false
                                                _currentDownloadId = ""
                                        }
                                }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.TriggerImport"))) { notification in
                            if let userInfo = notification.userInfo, let autoSign = userInfo["autoSign"] as? Bool {
                                _shouldAutoSignNext = autoSign
                            }
                            _isImportingPresenting = true
                        }
                        // Listen for import failure notifications
                        .onReceive(NotificationCenter.default.publisher(for: DownloadManager.importDidFailNotification)) { notification in
                                guard let userInfo = notification.userInfo,
                                          let downloadId = userInfo["downloadId"] as? String,
                                          downloadId == _currentDownloadId else { return }
                                
                                _importErrorMessage = userInfo["error"] as? String ?? "Unknown Error"
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        _importStatus = .failed
                                }
                                
                                // Auto-dismiss after showing error
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                                _showImportAnimation = false
                                                _currentDownloadId = ""
                                        }
                                }
                        }
                        // Listen for download failure notifications
                        .onReceive(NotificationCenter.default.publisher(for: DownloadManager.downloadDidFailNotification)) { notification in
                                guard let userInfo = notification.userInfo,
                                          let downloadId = userInfo["downloadId"] as? String,
                                          downloadId == _currentDownloadId else { return }
                                
                                _importErrorMessage = userInfo["error"] as? String ?? "Download Failed"
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        _importStatus = .failed
                                }
                                
                                // Auto-dismiss after showing error
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                                _showImportAnimation = false
                                                _currentDownloadId = ""
                                        }
                                }
                        }
                        // Listen for download progress notifications
                        .onReceive(NotificationCenter.default.publisher(for: DownloadManager.downloadDidProgressNotification)) { notification in
                                guard let userInfo = notification.userInfo,
                                          let downloadId = userInfo["downloadId"] as? String,
                                          downloadId == _currentDownloadId,
                                          let progress = userInfo["progress"] as? Double else { return }
                                
                                _downloadProgress = progress
                                
                                // Switch to processing status when download is complete (progress >= 0.99)
                                if progress >= 0.99 && _importStatus == .downloading {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                _importStatus = .processing
                                        }
                                }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.installApp"))) { _ in
                                if let latest = _signedApps.first {
                                        _selectedInstallAppPresenting = AnyApp(base: latest)
                                }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.openSigningView"))) { notification in
                                if let app = notification.object as? AppInfoPresentable {
                                        _selectedSigningAppPresenting = AnyApp(base: app)
                                }
                        }
                        .overlay {
                                if _showImportAnimation {
                                        ZStack {
                                                Color.black.opacity(0.5)
                                                        .ignoresSafeArea()
                                                        .transition(AnyTransition.opacity)
                                                
                                                VStack(spacing: 20) {
                                                        ZStack {
                                                                // Background circle with status color
                                                                Circle()
                                                                        .fill(
                                                                                _importStatus == .success 
                                                                                        ? Color.green
                                                                                        : _importStatus == .failed
                                                                                        ? Color.red
                                                                                        : Color.blue
                                                                        )
                                                                        .frame(width: 100, height: 100)
                                                                        .scaleEffect(_showImportAnimation ? 1.0 : 0.5)
                                                                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: _showImportAnimation)
                                                                
                                                                // Progress ring for downloading state
                                                                if _importStatus == .downloading {
                                                                        Circle()
                                                                                .stroke(Color.white.opacity(0.3), lineWidth: 6)
                                                                                .frame(width: 90, height: 90)
                                                                        
                                                                        Circle()
                                                                                .trim(from: 0, to: _downloadProgress)
                                                                                .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                                                                .frame(width: 90, height: 90)
                                                                                .rotationEffect(.degrees(-90))
                                                                                .animation(.easeInOut(duration: 0.2), value: _downloadProgress)
                                                                }
                                                                
                                                                Group {
                                                                        switch _importStatus {
                                                                        case .loading, .processing:
                                                                                ProgressView()
                                                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                                                        .scaleEffect(1.5)
                                                                        case .downloading:
                                                                                VStack(spacing: 2) {
                                                                                        Image(systemName: "arrow.down")
                                                                                                .font(.system(size: 28, weight: .bold))
                                                                                                .foregroundStyle(.white)
                                                                                        Text("\(Int(_downloadProgress * 100))%")
                                                                                                .font(.system(size: 14, weight: .bold))
                                                                                                .foregroundStyle(.white)
                                                                                }
                                                                        case .success:
                                                                                Image(systemName: "checkmark")
                                                                                        .font(.system(size: 50, weight: .bold))
                                                                                        .foregroundStyle(.white)
                                                                        case .failed:
                                                                                Image(systemName: "xmark")
                                                                                        .font(.system(size: 50, weight: .bold))
                                                                                        .foregroundStyle(.white)
                                                                        }
                                                                }
                                                                .scaleEffect(_showImportAnimation && (_importStatus == .success || _importStatus == .failed) ? 1.0 : (_importStatus == .downloading ? 1.0 : 0.8))
                                                                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay((_importStatus == .success || _importStatus == .failed) ? 0.1 : 0), value: _importStatus)
                                                        }
                                                        
                                                        VStack(spacing: 8) {
                                                                Text(_statusTitle)
                                                                        .font(.title2)
                                                                        .fontWeight(.bold)
                                                                        .foregroundStyle(.white)
                                                                
                                                                Text(_importedAppName)
                                                                        .font(.subheadline)
                                                                        .foregroundStyle(.white.opacity(0.8))
                                                                        .lineLimit(2)
                                                                        .multilineTextAlignment(.center)
                                                                        .padding(.horizontal, 40)
                                                                
                                                                // Show error message if failed
                                                                if _importStatus == .failed && !_importErrorMessage.isEmpty {
                                                                        Text(_importErrorMessage)
                                                                                .font(.caption)
                                                                                .foregroundStyle(.white.opacity(0.6))
                                                                                .lineLimit(3)
                                                                                .multilineTextAlignment(.center)
                                                                                .padding(.horizontal, 20)
                                                                                .padding(.top, 4)
                                                                }
                                                        }
                                                        .opacity(_showImportAnimation ? 1.0 : 0.0)
                                                        .offset(y: _showImportAnimation ? 0 : 20)
                                                        .animation(.easeOut(duration: 0.4).delay(0.2), value: _showImportAnimation)
                                                }
                                                .padding(40)
                                                .background(
                                                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                                                                .fill(Color(uiColor: .systemBackground))
                                                                .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
                                                )
                                                .scaleEffect(_showImportAnimation ? 1.0 : 0.8)
                                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: _showImportAnimation)
                                        }
                                }
                        }
                }
        }
        
        private var _statusTitle: String {
                switch _importStatus {
                case .loading:
                        return String.localized("Loading")
                case .downloading:
                        return String.localized("Downloading")
                case .processing:
                        return String.localized("Processing")
                case .success:
                        return String.localized("Import Successful!")
                case .failed:
                        return String.localized("Import Failed")
                }
        }
}

// MARK: - Extension: View Components
extension LibraryView {
    // MARK: - Simple Filter Chips
    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                let isSelected = _filterMode == mode
                let strokeColor: Color = {
                    switch mode {
                    case .all: return Color.accentColor
                    case .unsigned: return .orange
                    case .signed: return .green
                    }
                }()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        _filterMode = mode
                    }
                    HapticsManager.shared.softImpact()
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? strokeColor : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            if isSelected {
                                Capsule()
                                    .stroke(strokeColor, lineWidth: 1.5)
                                    .matchedGeometryEffect(id: "activeFilter", in: _namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            if totalAppCount >= 1 && !hideManager.isHidden("library.selectionButton") {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        _editMode = _editMode == .active ? .inactive : .active
                        if _editMode == .inactive {
                            _selectedApps.removeAll()
                        }
                    }
                    HapticsManager.shared.softImpact()
                } label: {
                    Text(_editMode == .active ? "Done" : "Edit")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Selection Action Bar
    @ViewBuilder
    private var selectionActionBar: some View {
        if _editMode == .active && !_selectedApps.isEmpty {
            HStack(spacing: 16) {
                Text("\(_selectedApps.count) Selected")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                let unsignedSelectedApps = getSelectedUnsignedApps()
                if !unsignedSelectedApps.isEmpty {
                    Button {
                        _showBatchSigningSheet = true
                    } label: {
                        Text("Sign \(unsignedSelectedApps.count)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                
                Button {
                    _showBatchDeleteConfirmation = true
                } label: {
                    Text("Delete")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
            .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private func getSelectedUnsignedApps() -> [AppInfoPresentable] {
        displayedApps.filter { app in
            _selectedApps.contains(app.uuid) && !app.isSigned
        }
    }
    
    private func getSelectedApps() -> [AppInfoPresentable] {
        displayedApps.filter { app in
            _selectedApps.contains(app.uuid)
        }
    }
    
    private func deleteSelectedApps() {
        let appsToDelete = getSelectedApps()
        for app in appsToDelete {
            Storage.shared.deleteApp(for: app)
        }
        _selectedApps.removeAll()
        _editMode = .inactive
        HapticsManager.shared.success()
    }
    
    // MARK: - Empty State View
    @ViewBuilder
    private var emptyStateView: some View {
        if #available(iOS 17, *) {
            ContentUnavailableView {
                Label {
                    Text("No Apps")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                } icon: {
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.system(size: 50, weight: .thin))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            } description: {
                Text("Import an IPA file to get started")
                    .font(.system(size: 15))
            } actions: {
                Menu {
                    _importActions()
                } label: {
                    Text("Import")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                .padding(.top, 10)
            }
            .padding(.top, 60)
        } else {
            VStack(spacing: 20) {
                Spacer(minLength: 80)

                Image(systemName: "square.stack.3d.up.slash")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(.secondary.opacity(0.6))

                VStack(spacing: 8) {
                    Text("No Apps")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("There is no apps here. Import an IPA file to get started!")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }

                Menu {
                    _importActions()
                } label: {
                    Text("Import")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.top, 8)

                Spacer(minLength: 80)
            }
        }
    }
    
    @ViewBuilder
    private func _importActions() -> some View {
        Button(String.localized("Import From Files"), systemImage: "folder") {
            _isImportingPresenting = true
        }
        Button(String.localized("Import From URL"), systemImage: "globe") {
            _isDownloadingPresenting = true
        }
    }
    
    private func exportApp(_ app: AppInfoPresentable) {
        guard app.isSigned, let archiveURL = app.archiveURL else { return }
        UIActivityViewController.show(activityItems: [archiveURL])
        HapticsManager.shared.success()
    }
}

// MARK: - Simplified Library App Row
struct LibraryAppRow: View {
    @Environment(\.editMode) private var editMode
    let app: AppInfoPresentable
    @Binding var selectedInfoAppPresenting: AnyApp?
    @Binding var selectedSigningAppPresenting: AnyApp?
    @Binding var selectedInstallAppPresenting: AnyApp?
    
    var body: some View {
        HStack(spacing: 12) {
            FRAppIconView(app: app, size: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name ?? String.localized("Unknown"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let version = app.version {
                        Text(version)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Text(app.isSigned ? String.localized("Signed") : String.localized("Unsigned"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(app.isSigned ? .green : .orange)
                }
            }
            
            Spacer()
            
            Button {
                if app.isSigned {
                    selectedInstallAppPresenting = AnyApp(base: app)
                } else {
                    selectedSigningAppPresenting = AnyApp(base: app)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: app.isSigned ? "arrow.down.circle.fill" : "signature")
                        .font(.system(size: 11, weight: .bold))

                    Text(app.isSigned ? String.localized("Install") : String.localized("Sign"))
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(app.isSigned ? Color.green : Color.accentColor)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if editMode?.wrappedValue == .inactive {
                selectedInfoAppPresenting = AnyApp(base: app)
            }
        }
    }
}

// MARK: - Library Download Header View
struct LibraryDownloadHeaderView: View {
    @ObservedObject var downloadManager: DownloadManager

    var body: some View {
        if !downloadManager.manualDownloads.isEmpty {
            VStack(spacing: 12) {
                if let firstDownload = downloadManager.manualDownloads.first {
                    LibraryDownloadItemView(download: firstDownload)

                    if downloadManager.manualDownloads.count > 1 {
                        HStack {
                            Spacer()
                            Text(verbatim: "+\(downloadManager.manualDownloads.count - 1) more")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.accentColor.opacity(0.1)))
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

struct LibraryDownloadItemView: View {
    let download: Download
    @State private var progress: Double = 0
    @State private var bytesDownloaded: Int64 = 0
    @State private var totalBytes: Int64 = 0
    @State private var unpackageProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: overallProgress >= 1.0 ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(overallProgress >= 1.0 ? .green : .accentColor)

                Text(download.fileName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Spacer()

                Text("\(Int(overallProgress * 100))%")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: overallProgress)
                .tint(.accentColor)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
        }
        .onReceive(download.$progress) { self.progress = $0 }
        .onReceive(download.$bytesDownloaded) { self.bytesDownloaded = $0 }
        .onReceive(download.$totalBytes) { self.totalBytes = $0 }
        .onReceive(download.$unpackageProgress) { self.unpackageProgress = $0 }
    }

    private var overallProgress: Double {
        download.onlyArchiving ? unpackageProgress : (0.3 * unpackageProgress) + (0.7 * progress)
    }
}


// MARK: - Modern Filter Chip
struct ModernFilterChip: View {
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .primary.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
                            .matchedGeometryEffect(id: "filterBackground", in: namespace)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(FilterChipButtonStyle())
    }
}

// MARK: - Compact Filter Chip (New Modern Design)
struct CompactFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor)
                        .matchedGeometryEffect(id: "compactFilterBackground", in: namespace)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(FilterChipButtonStyle())
    }
}



// MARK: - Filter Chip Button Style
struct FilterChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

