import Foundation
import Zip

// MARK: - Enterprise Certificate Model

struct EnterpriseCertificate: Identifiable {
	let id = UUID()
	let certificateName: String
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
	private let cacheIntervalSeconds: TimeInterval = 24 * 60 * 60
	private let lastFetchKey = "Feather.enterpriseCertLastFetch"
	private let cachedNamesKey = "Feather.enterpriseCertCachedNames"

	private var extractionDirectory: URL {
		let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
		return cachesDir.appendingPathComponent("enterpriseCertificates")
	}

	// MARK: Public

	/// Downloads the ZIP (if cache is absent or older than 24 hours), extracts it,
	/// and returns all valid certificate pairs plus any names removed since the last fetch.
	func fetchEnterpriseCertificates() async throws -> (certificates: [EnterpriseCertificate], removedCertificateNames: [String]) {
		let dir = extractionDirectory
		let now = Date()
		let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date

		let cacheExists = FileManager.default.fileExists(atPath: dir.path)
		let cacheIsStale = lastFetch.map { now.timeIntervalSince($0) >= cacheIntervalSeconds } ?? true

		if cacheExists && !cacheIsStale {
			print("[EnterpriseFetcher] Using cached certificates at \(dir.path)")
			let certs = try parseDirectories(in: dir)
			return (certs, [])
		}

		return try await performDownloadAndRefresh(to: dir, now: now)
	}

	/// Forces a fresh download and extraction regardless of the cache age.
	func refreshEnterpriseCertificates() async throws -> (certificates: [EnterpriseCertificate], removedCertificateNames: [String]) {
		UserDefaults.standard.removeObject(forKey: lastFetchKey)
		return try await fetchEnterpriseCertificates()
	}

	// MARK: Private

	private func performDownloadAndRefresh(to dir: URL, now: Date) async throws -> (certificates: [EnterpriseCertificate], removedCertificateNames: [String]) {
		let previousNames = (UserDefaults.standard.array(forKey: cachedNamesKey) as? [String]) ?? []

		try? FileManager.default.removeItem(at: dir)
		try await downloadAndExtract(to: dir)

		let certs = try parseDirectories(in: dir)
		let currentNames = Set(certs.map(\.certificateName))
		let removedNames = previousNames.filter { !currentNames.contains($0) }

		UserDefaults.standard.set(Array(currentNames), forKey: cachedNamesKey)
		UserDefaults.standard.set(now, forKey: lastFetchKey)

		print("[EnterpriseFetcher] Parsed \(certs.count) valid certificates")
		return (certs, removedNames)
	}

	private func downloadAndExtract(to destination: URL) async throws {
		let fm = FileManager.default

		// Ensure the cache directory exists before writing anything
		try fm.createDirectory(at: destination, withIntermediateDirectories: true)

		let zipPath = destination.appendingPathComponent("certificates.zip")

		// Download the ZIP data
		print("[EnterpriseFetcher] Starting ZIP download from \(remoteZipURL.absoluteString)")
		let (data, response) = try await URLSession.shared.data(from: remoteZipURL)
		guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
			let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
			print("[EnterpriseFetcher] Download failed with status code: \(statusCode)")
			throw EnterpriseFetcherError.downloadFailed
		}
		print("[EnterpriseFetcher] Download completed, \(data.count) bytes received")

		// Write the downloaded data to certificates.zip inside the cache directory
		try data.write(to: zipPath)
		print("[EnterpriseFetcher] ZIP written to \(zipPath.path)")

		// Extract the ZIP contents into the enterpriseCertificates directory
		print("[EnterpriseFetcher] Starting ZIP extraction")
		do {
			try Zip.unzipFile(zipPath, destination: destination, overwrite: true, password: nil)
		} catch {
			print("[EnterpriseFetcher] Extraction failed: \(error.localizedDescription)")
			try? fm.removeItem(at: destination)
			throw EnterpriseFetcherError.extractionFailed
		}
		print("[EnterpriseFetcher] Extraction finished")

		// Clean up the ZIP file after extraction
		try? fm.removeItem(at: zipPath)
	}

	private func parseDirectories(in directory: URL) throws -> [EnterpriseCertificate] {
		let fm = FileManager.default
		let contents = try fm.contentsOfDirectory(
			at: directory,
			includingPropertiesForKeys: [.isDirectoryKey],
			options: [.skipsHiddenFiles]
		)

		print("[EnterpriseFetcher] Found \(contents.count) items in \(directory.lastPathComponent)")

		var certificates: [EnterpriseCertificate] = []

		for item in contents {
			let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])
			guard resourceValues.isDirectory == true else { continue }

			let subContents = (try? fm.contentsOfDirectory(
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
					certificateName: item.lastPathComponent,
					p12URL: p12,
					provisionURL: provision
				))
				print("[EnterpriseFetcher] Valid certificate: \(item.lastPathComponent)")
			}
		}

		print("[EnterpriseFetcher] Total valid certificates parsed: \(certificates.count)")
		return certificates.sorted { $0.certificateName.localizedCompare($1.certificateName) == .orderedAscending }
	}
}
