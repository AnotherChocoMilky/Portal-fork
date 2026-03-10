// created by dylan on 3/9/26

import Foundation
enum EnterpriseFetcherError: LocalizedError {
	case downloadFailed

	var errorDescription: String? {
		switch self {
		case .downloadFailed:
			return NSLocalizedString("Failed to download the certificates archive.", comment: "")
		}
	}
}

// MARK: - Fetcher

@MainActor
final class CertificateEnterpriseFetcher: ObservableObject {
	static let shared = CertificateEnterpriseFetcher()

	@Published var isFetching: Bool = false
	@Published var errorMessage: String?

	private let repositoryURL = URL(string: "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/portal/resources/certificates.zip")!

	private let documentsRoot = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	private var enterpriseFolder: URL {
		documentsRoot
			.appendingPathComponent("Certificates")
			.appendingPathComponent("EnterpriseCerts")
	}
	private var zipFile: URL { enterpriseFolder.appendingPathComponent("certificates.zip") }

	// MARK: Public

	func fetchEnterpriseCertificates(forceRefresh: Bool) async throws {
		guard !isFetching else { return }
		isFetching = true
		errorMessage = nil

		defer { self.isFetching = false }

		do {
			let fm = FileManager.default

			if !fm.fileExists(atPath: enterpriseFolder.path) {
				try fm.createDirectory(at: enterpriseFolder, withIntermediateDirectories: true)
			}

			if forceRefresh, fm.fileExists(atPath: zipFile.path) {
				try fm.removeItem(at: zipFile)
			}

			let (data, _) = try await URLSession.shared.data(from: repositoryURL)
			try data.write(to: zipFile, options: .atomic)
		} catch {
			errorMessage = EnterpriseFetcherError.downloadFailed.localizedDescription
			throw EnterpriseFetcherError.downloadFailed
		}
	}
}
