import Foundation
import Zip

// MARK: - Enterprise Certificate Model

struct EnterpriseCertificate: Identifiable {
	let id = UUID()
	let name: String
	let p12URL: URL
	let provisionURL: URL
}

// MARK: - Errors

enum EnterpriseFetcherError: LocalizedError {
	case downloadFailed
	case extractionFailed

	var errorDescription: String? {
		switch self {
		case .downloadFailed:
			return NSLocalizedString("Failed to download the certificates archive.", comment: "")
		case .extractionFailed:
			return NSLocalizedString("Failed to extract the certificates archive.", comment: "")
		}
	}
}

// MARK: - Fetcher

final class CertificateEnterpriseFetcher {
	static let shared = CertificateEnterpriseFetcher()

	private let remoteZipURL = URL(string: "https://github.com/WSF-Team/WSF/raw/refs/heads/main/portal/resources/certificates.zip")!

	private var extractionDirectory: URL {
		FileManager.default.temporaryDirectory.appendingPathComponent("enterpriseCertificates")
	}

	// MARK: Public

	/// Downloads the ZIP (if not already cached), extracts it, and returns all
	/// valid certificate pairs found inside the archive.
	func fetchEnterpriseCertificates() async throws -> [EnterpriseCertificate] {
		let dir = extractionDirectory

		if !FileManager.default.fileExists(atPath: dir.path) {
			try await downloadAndExtract(to: dir)
		}

		return try parseDirectories(in: dir)
	}

	// MARK: Private

	private func downloadAndExtract(to destination: URL) async throws {
		let tempZipPath = FileManager.default.temporaryDirectory
			.appendingPathComponent("certificates_enterprise_\(UUID().uuidString).zip")

		let (localURL, response) = try await URLSession.shared.download(from: remoteZipURL)
		guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
			try? FileManager.default.removeItem(at: localURL)
			throw EnterpriseFetcherError.downloadFailed
		}

		try? FileManager.default.removeItem(at: tempZipPath)
		try FileManager.default.moveItem(at: localURL, to: tempZipPath)
		defer { try? FileManager.default.removeItem(at: tempZipPath) }

		try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			DispatchQueue.global(qos: .utility).async {
				do {
					try Zip.unzipFile(tempZipPath, destination: destination, overwrite: true, password: nil)
					continuation.resume()
				} catch {
					try? FileManager.default.removeItem(at: destination)
					continuation.resume(throwing: EnterpriseFetcherError.extractionFailed)
				}
			}
		}
	}

	private func parseDirectories(in directory: URL) throws -> [EnterpriseCertificate] {
		let contents = try FileManager.default.contentsOfDirectory(
			at: directory,
			includingPropertiesForKeys: [.isDirectoryKey],
			options: [.skipsHiddenFiles]
		)

		var certificates: [EnterpriseCertificate] = []

		for item in contents {
			let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])
			guard resourceValues.isDirectory == true else { continue }

			let subContents = (try? FileManager.default.contentsOfDirectory(
				at: item,
				includingPropertiesForKeys: nil,
				options: [.skipsHiddenFiles]
			)) ?? []

			var p12URL: URL?
			var provisionURL: URL?

			for file in subContents {
				let ext = file.pathExtension.lowercased()
				if ext == "p12", p12URL == nil {
					p12URL = file
				} else if ext == "mobileprovision", provisionURL == nil {
					provisionURL = file
				}
			}

			if let p12 = p12URL, let provision = provisionURL {
				certificates.append(EnterpriseCertificate(
					name: item.lastPathComponent,
					p12URL: p12,
					provisionURL: provision
				))
			}
		}

		return certificates.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
	}
}
