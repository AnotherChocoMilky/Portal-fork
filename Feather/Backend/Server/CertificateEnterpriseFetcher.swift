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

@MainActor
final class CertificateEnterpriseFetcher: ObservableObject {
	static let shared = CertificateEnterpriseFetcher()

	@Published var certificates: [EnterpriseCertificate] = []
	@Published var isLoading = false
	@Published var errorMessage: String? = nil

	private let remoteZipURL = URL(string: "https://github.com/WSF-Team/WSF/raw/refs/heads/main/portal/resources/certificates.zip")!
	private let cacheIntervalSeconds: TimeInterval = 24 * 60 * 60
	private let lastFetchKey = "Feather.enterpriseCertLastFetch"

	private var cacheDirectory: URL {
		let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
		return cachesDir.appendingPathComponent("enterpriseCertificates")
	}

	// MARK: Public

	func fetchEnterpriseCertificates(forceRefresh: Bool) {
		guard !isLoading else { return }
		isLoading = true
		errorMessage = nil

		Task {
			defer { isLoading = false }
			do {
				let dir = cacheDirectory
				let zipPath = dir.appendingPathComponent("certificates.zip")
				let fm = FileManager.default

				if forceRefresh {
					try? fm.removeItem(at: dir)
				} else {
					let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date
					let cacheIsValid = lastFetch.map { Date().timeIntervalSince($0) < cacheIntervalSeconds } ?? false
					if cacheIsValid && fm.fileExists(atPath: dir.path) {
						print("[EnterpriseFetcher] Using cached certificates")
						let certs = try parseDirectories(in: dir)
						certificates = certs
						return
					}
				}

				try fm.createDirectory(at: dir, withIntermediateDirectories: true)

				print("[EnterpriseFetcher] Starting certificate download")
				let (data, response) = try await URLSession.shared.data(from: remoteZipURL)
				guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
					throw EnterpriseFetcherError.downloadFailed
				}
				print("[EnterpriseFetcher] ZIP download completed")

				try data.write(to: zipPath)

				// Remove any previously extracted certificate folders before extraction
				let existingItems = (try? fm.contentsOfDirectory(atPath: dir.path)) ?? []
				for item in existingItems {
					if item == "certificates.zip" { continue }
					do {
						try fm.removeItem(at: dir.appendingPathComponent(item))
					} catch {
						print("[EnterpriseFetcher] Warning: could not remove stale item '\(item)': \(error.localizedDescription)")
					}
				}

				print("[EnterpriseFetcher] ZIP extraction started")
				do {
					try Zip.unzipFile(zipPath, destination: dir, overwrite: true, password: nil)
				} catch {
					print("[EnterpriseFetcher] Extraction failed: \(error.localizedDescription)")
					throw EnterpriseFetcherError.extractionFailed
				}
				print("[EnterpriseFetcher] ZIP extraction completed")

				let certs = try parseDirectories(in: dir)
				certificates = certs

				UserDefaults.standard.set(Date(), forKey: lastFetchKey)
			} catch {
				errorMessage = error.localizedDescription
			}
		}
	}

	// MARK: Private

	private func parseDirectories(in directory: URL) throws -> [EnterpriseCertificate] {
		let fm = FileManager.default
		let items = try fm.contentsOfDirectory(atPath: directory.path)

		print("[EnterpriseFetcher] Number of folders discovered: \(items.count)")

		var result: [EnterpriseCertificate] = []

		for item in items {
			if item == "certificates.zip" { continue }

			let itemURL = directory.appendingPathComponent(item)
			var isDirectory: ObjCBool = false
			guard fm.fileExists(atPath: itemURL.path, isDirectory: &isDirectory),
				  isDirectory.boolValue else { continue }

			let subItems = (try? fm.contentsOfDirectory(atPath: itemURL.path)) ?? []

			var p12URL: URL?
			var provisionURL: URL?

			for file in subItems {
				let fileURL = itemURL.appendingPathComponent(file)
				let ext = fileURL.pathExtension.lowercased()
				if ext == "p12", p12URL == nil {
					p12URL = fileURL
				} else if ext == "mobileprovision", provisionURL == nil {
					provisionURL = fileURL
				}
			}

			if let p12 = p12URL, let provision = provisionURL {
				result.append(EnterpriseCertificate(
					certificateName: itemURL.lastPathComponent,
					p12URL: p12,
					provisionURL: provision
				))
				print("[EnterpriseFetcher] Valid certificate: \(itemURL.lastPathComponent)")
			}
		}

		print("[EnterpriseFetcher] Number of valid certificates parsed: \(result.count)")
		return result.sorted { $0.certificateName.localizedCompare($1.certificateName) == .orderedAscending }
	}
}
