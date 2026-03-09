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
	case zipNotFound
	case extractionFailed

	var errorDescription: String? {
		switch self {
		case .downloadFailed:
			return NSLocalizedString("Failed to download the certificates archive.", comment: "")
		case .zipNotFound:
			return NSLocalizedString("The downloaded archive could not be found on disk.", comment: "")
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
	@Published var isFetching: Bool = false
	@Published var errorMessage: String?

	private let repositoryURL = URL(string: "https://github.com/WSF-Team/WSF/raw/refs/heads/main/portal/resources/certificates.zip")!

	private let cacheRoot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	private var enterpriseFolder: URL { cacheRoot.appendingPathComponent("enterpriseCertificates") }
	private var zipFile: URL { enterpriseFolder.appendingPathComponent("certificates.zip") }
	private var extractedFolder: URL { enterpriseFolder.appendingPathComponent("extracted") }

	// MARK: Public

	func fetchEnterpriseCertificates(forceRefresh: Bool) {
		guard !isFetching else { return }
		isFetching = true
		errorMessage = nil

		Task {
			defer { self.isFetching = false }
			do {
				print("[EnterpriseFetcher] Starting certificate fetch")

				let fm = FileManager.default

				// Step 1 – Prepare directories
				if forceRefresh {
					try? fm.removeItem(at: enterpriseFolder)
				}
				if !fm.fileExists(atPath: enterpriseFolder.path) {
					try fm.createDirectory(at: enterpriseFolder, withIntermediateDirectories: true)
				}

				// Step 2 – Download the ZIP archive
				let (data, _) = try await URLSession.shared.data(from: repositoryURL)
				print("[EnterpriseFetcher] Download complete")

				try data.write(to: zipFile)

				guard fm.fileExists(atPath: zipFile.path) else {
					self.errorMessage = EnterpriseFetcherError.zipNotFound.localizedDescription
					return
				}

				if let attrs = try? fm.attributesOfItem(atPath: zipFile.path),
				   let size = attrs[.size] as? Int {
					print("[EnterpriseFetcher] ZIP written to disk (\(size) bytes)")
				} else {
					print("[EnterpriseFetcher] ZIP written to disk")
				}

				// Step 3 – Extract the ZIP
				if fm.fileExists(atPath: extractedFolder.path) {
					try fm.removeItem(at: extractedFolder)
				}
				try fm.createDirectory(at: extractedFolder, withIntermediateDirectories: true)

				print("[EnterpriseFetcher] Extraction started")
				do {
					try Zip.unzipFile(zipFile, destination: extractedFolder, overwrite: true, password: nil)
				} catch {
					print("[EnterpriseFetcher] Extraction failed: \(error.localizedDescription)")
					throw EnterpriseFetcherError.extractionFailed
				}
				print("[EnterpriseFetcher] Extraction finished")

				if fm.fileExists(atPath: extractedFolder.path),
				   let extractedContents = try? fm.contentsOfDirectory(atPath: extractedFolder.path) {
					print("[EnterpriseFetcher] Extracted directory contents: \(extractedContents)")
				}

				// Step 4 – Parse certificate folders
				let certs = try parseDirectories(in: extractedFolder)
				self.certificates = certs
			} catch {
				self.errorMessage = error.localizedDescription
			}
		}
	}

	// MARK: Private

	private func parseDirectories(in directory: URL) throws -> [EnterpriseCertificate] {
		let fm = FileManager.default
		let items = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

		print("[EnterpriseFetcher] Number of folders discovered: \(items.count)")

		var result: [EnterpriseCertificate] = []

		for folder in items {
			var isDirectory: ObjCBool = false
			guard fm.fileExists(atPath: folder.path, isDirectory: &isDirectory),
				  isDirectory.boolValue else { continue }

			let files = (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []

			guard let p12URL = files.first(where: { $0.pathExtension.lowercased() == "p12" }),
				  let provisionURL = files.first(where: { $0.pathExtension.lowercased() == "mobileprovision" }) else {
				continue
			}

			result.append(EnterpriseCertificate(
				certificateName: folder.lastPathComponent,
				p12URL: p12URL,
				provisionURL: provisionURL
			))
			print("[EnterpriseFetcher] Valid certificate: \(folder.lastPathComponent)")
		}

		print("[EnterpriseFetcher] Number of valid certificates parsed: \(result.count)")

		if result.isEmpty {
			print("[EnterpriseFetcher] No certificates found. Full extracted directory structure:")
			printDirectoryStructure(at: directory, indent: "  ")
		}

		return result.sorted { $0.certificateName.localizedCompare($1.certificateName) == .orderedAscending }
	}

	private func printDirectoryStructure(at url: URL, indent: String) {
		let fm = FileManager.default
		guard let items = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else { return }
		for item in items {
			var isDirectory: ObjCBool = false
			fm.fileExists(atPath: item.path, isDirectory: &isDirectory)
			if isDirectory.boolValue {
				print("\(indent)\(item.lastPathComponent)/")
				printDirectoryStructure(at: item, indent: indent + "  ")
			} else {
				print("\(indent)\(item.lastPathComponent)")
			}
		}
	}
}
