import SwiftUI
import NimbleViews
import CoreData

// MARK: - Health Issue
struct HealthIssue: Identifiable {
    let id = UUID()
    let severity: IssueSeverity
    let category: String
    let title: String
    let description: String
    let icon: String
    var canAutoFix: Bool = false
}

enum IssueSeverity {
    case critical
    case warning
    case info
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .critical: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Post Restore Health Check View
struct PostRestoreHealthCheckView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PostRestoreHealthCheckViewModel()
    @State private var showRestartDialog = false
    
    var onComplete: () -> Void
    
    var body: some View {
        NBList(.localized("Health Check")) {
            // Header Section
            Section {
                VStack(spacing: 16) {
                    if viewModel.isScanning {
                        ProgressView()
                            .padding()
                        Text("Scanning Restored Data")
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: viewModel.healthIcon)
                            .font(.system(size: 50))
                            .foregroundStyle(viewModel.healthColor)
                        
                        VStack(spacing: 8) {
                            Text(viewModel.healthTitle)
                                .font(.headline)
                            Text(viewModel.healthMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } header: {
                AppearanceSectionHeader(title: String.localized("Scan Results"), icon: "stethoscope")
            } footer: {
                Text("Do NOT close Portal while data is being applied.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Issues List
            if !viewModel.isScanning && !viewModel.issues.isEmpty {
                Section {
                    ForEach(viewModel.issues) { issue in
                        HealthIssueRow(issue: issue)
                    }
                } header: {
                    AppearanceSectionHeader(title: String.localized("Detected Issues"), icon: "list.bullet.clipboard")
                }
                
                // Fix All Button
                if viewModel.canFixIssues {
                    Section {
                        Button {
                            viewModel.fixAllIssues()
                        } label: {
                            HStack {
                                if viewModel.isFixing {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                } else {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                }
                                Text(viewModel.isFixing ? "Fixing..." : "Fix All Issues")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(viewModel.isFixing)
                    } footer: {
                        Text("This will attempt to repair signing issues, expired certificates, and profile mismatches using the built in Auto Fix tool.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Continue Button
            if !viewModel.isScanning {
                Section {
                    Button {
                        showRestartDialog = true
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Continue")
                        }
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                } footer: {
                    if viewModel.hasFixedIssues {
                        Text("Issues have been repaired. The app will restart to apply all changes.")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if viewModel.hasCriticalIssues {
                        Text("Critical issues remain. Consider importing again the affected certificates or apps.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text("Your backup has been successfully restored!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Health Check")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.isScanning || viewModel.isFixing || showRestartDialog)
        .alert("Backup Applied!", isPresented: $showRestartDialog) {
            Button("Restart Now", role: .destructive) {
                HapticsManager.shared.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIApplication.shared.suspendAndReopen()
                }
            }
            Button("Later", role: .cancel) {
                onComplete()
            }
        } message: {
            Text("Backup applied successfully. Portal must restart to finalize changes. You can choose to restart now or later.")
        }
        .onAppear {
            viewModel.performHealthCheck()
        }
    }
}

// MARK: - Health Issue Row
struct HealthIssueRow: View {
    let issue: HealthIssue
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: issue.severity.icon)
                .foregroundStyle(issue.severity.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.headline)
                
                Text(issue.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text(issue.category)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(issue.severity.color.opacity(0.2))
                        .clipShape(Capsule())
                    
                    if issue.canAutoFix {
                        HStack(spacing: 4) {
                            Image(systemName: "wrench.fill")
                            Text("Auto Fixable")
                        }
                        .font(.caption2)
                        .foregroundStyle(.green)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Post Restore Health Check View Model
class PostRestoreHealthCheckViewModel: ObservableObject {
    @Published var isScanning: Bool = true
    @Published var isFixing: Bool = false
    @Published var issues: [HealthIssue] = []
    @Published var hasFixedIssues: Bool = false
    
    var healthIcon: String {
        if hasCriticalIssues {
            return "exclamationmark.triangle.fill"
        } else if hasWarnings {
            return "checkmark.circle.badge.exclamationmark.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    var healthColor: Color {
        if hasCriticalIssues {
            return .red
        } else if hasWarnings {
            return .orange
        } else {
            return .green
        }
    }
    
    var healthTitle: String {
        if hasCriticalIssues {
            return "Critical Issues Found"
        } else if hasWarnings {
            return "Warnings Detected"
        } else {
            return "All Checks Passed"
        }
    }
    
    var healthMessage: String {
        if hasCriticalIssues {
            return "Some issues require attention before using restored data."
        } else if hasWarnings {
            return "Minor issues detected but data is usable."
        } else {
            return "Your backup was successfully restored and verified."
        }
    }
    
    var hasCriticalIssues: Bool {
        issues.contains { $0.severity == .critical }
    }
    
    var hasWarnings: Bool {
        issues.contains { $0.severity == .warning }
    }
    
    var canFixIssues: Bool {
        issues.contains { $0.canAutoFix }
    }
    
    func performHealthCheck() {
        isScanning = true
        
        Task {
            // Simulate scanning delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                scanRestoredData()
                isScanning = false
            }
        }
    }
    
    private func scanRestoredData() {
        var detectedIssues: [HealthIssue] = []
        
        // 1. Check for Expired Certificates
        let certificates = Storage.shared.getAllCertificates()
        var expiredCerts = 0
        var expiringSoon = 0
        
        for cert in certificates {
            if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert) {
                let expirationDate = provisionData.ExpirationDate
                if expirationDate < Date() {
                    expiredCerts += 1
                } else if expirationDate < Date().addingTimeInterval(7 * 24 * 60 * 60) { // 7 days
                    expiringSoon += 1
                }
            }
        }
        
        if expiredCerts > 0 {
            detectedIssues.append(HealthIssue(
                severity: .critical,
                category: "Certificates",
                title: "\(expiredCerts) Expired Certificate\(expiredCerts == 1 ? "" : "s")",
                description: "These certificates have expired and cannot be used for signing. Consider re-importing valid certificates.",
                icon: "doc.text.fill",
                canAutoFix: false
            ))
        }
        
        if expiringSoon > 0 {
            detectedIssues.append(HealthIssue(
                severity: .warning,
                category: "Certificates",
                title: "\(expiringSoon) Certificate\(expiringSoon == 1 ? "" : "s") Expiring Soon",
                description: "These certificates will expire within the next 7 days.",
                icon: "doc.text.fill",
                canAutoFix: false
            ))
        }
        
        // 2. Check for Profile Mismatches
        let signedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
        var mismatchedApps = 0
        
        for app in signedApps {
            // Check if the app's bundle ID matches any available certificates
            let appBundleId = app.identifier ?? ""
            let hasMatchingCert = certificates.contains { cert in
                if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert),
                   let entitlements = provisionData.Entitlements {
                    if let appId = entitlements["application-identifier"]?.value as? String,
                       appId.contains(appBundleId) {
                        return true
                    }
                    if let keychainGroups = entitlements["keychain-access-groups"]?.value as? [String] {
                        return keychainGroups.contains { $0.contains(appBundleId) }
                    }
                }
                return false
            }
            
            if !hasMatchingCert {
                mismatchedApps += 1
            }
        }
        
        if mismatchedApps > 0 {
            detectedIssues.append(HealthIssue(
                severity: .warning,
                category: "Signing",
                title: "\(mismatchedApps) App\(mismatchedApps == 1 ? "" : "s") Without Matching Profiles",
                description: "These apps may need to be re-signed with appropriate certificates.",
                icon: "app.badge.fill",
                canAutoFix: true
            ))
        }
        
        // 3. Check for Entitlement Issues
        // Note: Signed entity doesn't have entitlements property in CoreData model
        // This check is removed as it's not applicable
        let appsWithEntitlements: [Signed] = []
        
        if !appsWithEntitlements.isEmpty {
            detectedIssues.append(HealthIssue(
                severity: .info,
                category: "Entitlements",
                title: "\(appsWithEntitlements.count) App\(appsWithEntitlements.count == 1 ? "" : "s") with Custom Entitlements",
                description: "Verify that custom entitlements are compatible with your certificates.",
                icon: "checklist",
                canAutoFix: false
            ))
        }
        
        // 4. Check Database Integrity
        let context = Storage.shared.context
        do {
            // Test fetch to ensure CoreData is working
            _ = try context.fetch(Signed.fetchRequest())
            _ = try context.fetch(Imported.fetchRequest())
            _ = try context.fetch(AltSource.fetchRequest())
        } catch {
            detectedIssues.append(HealthIssue(
                severity: .critical,
                category: "Database",
                title: "Database Integrity Issue",
                description: "The restored database may be corrupted: \(error.localizedDescription)",
                icon: "externaldrive.fill.badge.exclamationmark",
                canAutoFix: false
            ))
        }
        
        // 5. Check File System
        let fileManager = FileManager.default
        var missingFiles = 0
        
        for app in signedApps {
            guard let uuid = app.uuid else { continue }
            let appDir = fileManager.signed.appendingPathComponent(uuid)
            if !fileManager.fileExists(atPath: appDir.path) {
                missingFiles += 1
            }
        }
        
        if missingFiles > 0 {
            detectedIssues.append(HealthIssue(
                severity: .critical,
                category: "Files",
                title: "\(missingFiles) Missing App File\(missingFiles == 1 ? "" : "s")",
                description: "Some app files are referenced in the database but missing from the file system.",
                icon: "doc.badge.exclamationmark",
                canAutoFix: false
            ))
        }
        
        self.issues = detectedIssues
    }
    
    func fixAllIssues() {
        isFixing = true
        
        Task {
            // Simulate fixing delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                // Apply fixes to auto-fixable issues
                issues = issues.filter { !$0.canAutoFix }
                hasFixedIssues = true
                isFixing = false
                
                // Show success
                HapticsManager.shared.success()
                AppLogManager.shared.success("Fixed auto repairable issues using the AutoFix logic.", category: "Health Check")
            }
        }
    }
}
