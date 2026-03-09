import Foundation
import Zip

// MARK: - Enterprise Certificate Model

struct EnterpriseCertificate: Identifiable {
	let id = UUID()
	let certificateName: String
	let p12URL: URL
	let provisionURL: URL
	let password: String
	let expirationDate: Date?
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

	/// Parses the ExpirationDate from a .mobileprovision file.
	static func parseProvisionExpiration(provisionURL: URL) -> Date? {
		guard let data = try? Data(contentsOf: provisionURL) else { return nil }

		// mobileprovision files embed a plist as an XML section; locate it by finding
		// the <?xml … tag and the matching </plist> closing tag.
		guard let xmlStart = data.range(of: Data("<?xml".utf8)),
			  let xmlEnd   = data.range(of: Data("</plist>".utf8)) else { return nil }

		let plistRange = xmlStart.lowerBound ..< xmlEnd.upperBound
		let plistData  = data.subdata(in: plistRange)

		guard let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil),
			  let dict  = plist as? [String: Any] else { return nil }

		return dict["ExpirationDate"] as? Date
	}

	/// Reads already-extracted certificate folders from disk without re-extracting.
	/// Path: Documents/Certificates/EnterpriseCerts/extracted/certificates
	static func loadExtractedCertificates() -> [EnterpriseCertificate] {
		let fm = FileManager.default

		guard let documentsRoot = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
			print("[EnterpriseCertExtracter] Could not resolve Documents directory")
			return []
		}

		let certificatesDir = documentsRoot
			.appendingPathComponent("Certificates")
			.appendingPathComponent("EnterpriseCerts")
			.appendingPathComponent("extracted")
			.appendingPathComponent("certificates")

		guard fm.fileExists(atPath: certificatesDir.path) else {
			print("[EnterpriseCertExtracter] Extracted certificates directory does not exist: \(certificatesDir.path)")
			return []
		}

		guard let items = try? fm.contentsOfDirectory(at: certificatesDir, includingPropertiesForKeys: nil) else {
			print("[EnterpriseCertExtracter] Failed to list contents of: \(certificatesDir.path)")
			return []
		}

		print("[EnterpriseCertExtracter] Number of certificate folders discovered: \(items.count)")

		var certificates: [EnterpriseCertificate] = []

		for folder in items {
			var isDirectory: ObjCBool = false
			guard fm.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else { continue }

			let certificateName = folder.lastPathComponent
			print("[EnterpriseCertExtracter] Found certificate folder: \(certificateName)")

			let files = (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []

			guard let p12URL = files.first(where: { $0.pathExtension == "p12" }),
				  let provisionURL = files.first(where: { $0.pathExtension == "mobileprovision" }) else {
				continue
			}

			let expiration = EnterpriseCertExtracter.parseProvisionExpiration(provisionURL: provisionURL)
			certificates.append(EnterpriseCertificate(
				certificateName: certificateName,
				p12URL: p12URL,
				provisionURL: provisionURL,
				password: "WSF",
				expirationDate: expiration
			))
		}

		print("[EnterpriseCertExtracter] Number of valid certificates parsed: \(certificates.count)")
		return certificates.sorted { $0.certificateName.localizedCompare($1.certificateName) == .orderedAscending }
	}

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

			let expiration = EnterpriseCertExtracter.parseProvisionExpiration(provisionURL: provisionURL)
			certificates.append(EnterpriseCertificate(
				certificateName: folder.lastPathComponent,
				p12URL: p12URL,
				provisionURL: provisionURL,
				password: "WSF",
				expirationDate: expiration
			))
		}

		return certificates.sorted { $0.certificateName.localizedCompare($1.certificateName) == .orderedAscending }
	}
}
