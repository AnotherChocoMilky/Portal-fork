import Foundation
import Zip

// MARK: - Enterprise Certificate Model

struct EnterpriseCertificate: Identifiable {
	let id = UUID()
	let certificateName: String
	let p12URL: URL
	let provisionURL: URL
	let password: String
}

// MARK: - Errors

enum EnterpriseExtracterError: LocalizedError {
	case zipNotDownloaded
	case extractionFailed

	var errorDescription: String? {
		switch self {
		case .zipNotDownloaded:
			return NSLocalizedString("The certificates archive has not been downloaded yet.", comment: "")
		case .extractionFailed:
			return NSLocalizedString("Failed to extract the certificates archive.", comment: "")
		}
	}
}

// MARK: - Extracter

final class EnterpriseCertExtracter {
	func extractEnterpriseCertificates() throws -> [EnterpriseCertificate] {
		let fm = FileManager.default

		guard let documentsRoot = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			throw EnterpriseExtracterError.zipNotDownloaded
		}

		let enterpriseFolder = documentsRoot
			.appendingPathComponent("Certificates")
			.appendingPathComponent("EnterpriseCerts")
		if !fm.fileExists(atPath: enterpriseFolder.path) {
			try fm.createDirectory(at: enterpriseFolder, withIntermediateDirectories: true)
		}

		let zipURL = enterpriseFolder.appendingPathComponent("certificates.zip")
		guard fm.fileExists(atPath: zipURL.path) else {
			throw EnterpriseExtracterError.zipNotDownloaded
		}

		let extractedFolder = enterpriseFolder.appendingPathComponent("extracted")
		if fm.fileExists(atPath: extractedFolder.path) {
			try fm.removeItem(at: extractedFolder)
		}
		try fm.createDirectory(at: extractedFolder, withIntermediateDirectories: true)

		do {
			try Zip.unzipFile(zipURL, destination: extractedFolder, overwrite: true, password: nil)
		} catch {
			throw EnterpriseExtracterError.extractionFailed
		}

		let items = try fm.contentsOfDirectory(at: extractedFolder, includingPropertiesForKeys: nil)
		var certificates: [EnterpriseCertificate] = []

		for folder in items {
			var isDirectory: ObjCBool = false
			guard fm.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else { continue }

			let files = (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []

			guard let p12URL = files.first(where: { $0.pathExtension.lowercased() == "p12" }),
				  let provisionURL = files.first(where: { $0.pathExtension.lowercased() == "mobileprovision" }) else {
				continue
			}

			certificates.append(EnterpriseCertificate(
				certificateName: folder.lastPathComponent,
				p12URL: p12URL,
				provisionURL: provisionURL,
				password: "WSF"
			))
		}

		return certificates.sorted { $0.certificateName.localizedCompare($1.certificateName) == .orderedAscending }
	}
}
