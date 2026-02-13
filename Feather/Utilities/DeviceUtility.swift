import UIKit
import Darwin

extension UIDevice {
    /// Returns a human-readable name for the device model
    var humanReadableModelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        switch identifier {
        // iPhone 16
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"

        // iPhone 15
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"

        // iPhone 14
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"

        // iPhone 13
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"

        // iPhone 12
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"

        // iPhone 11
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"

        // iPhone XS / XR
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"

        // iPhone X / 8
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"

        // iPhone SE
        case "iPhone8,4": return "iPhone SE (1st generation)"
        case "iPhone12,8": return "iPhone SE (2nd generation)"
        case "iPhone14,6": return "iPhone SE (3rd generation)"

        // iPads
        case "iPad11,6", "iPad11,7": return "iPad (8th generation)"
        case "iPad12,1", "iPad12,2": return "iPad (9th generation)"
        case "iPad13,18", "iPad13,19": return "iPad (10th generation)"
        case "iPad13,1", "iPad13,2": return "iPad Air (4th generation)"
        case "iPad13,16", "iPad13,17": return "iPad Air (5th generation)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11-inch (3rd generation)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9-inch (5th generation)"
        case "iPad14,3", "iPad14,4": return "iPad Pro 11-inch (4th generation)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 12.9-inch (6th generation)"

        // Simulators
        case "i386", "x86_64", "arm64": return "Simulator (\(identifier))"

        default: return identifier
        }
    }

    /// Attempts to grab the UDID from various sources
    func grabUDID() -> String {
        getDeviceIdentifier().id
    }

    struct DeviceIdentifier {
        let id: String
        let isRealUDID: Bool
        var label: String { isRealUDID ? "UDID" : "Device ID" }
    }

    func getDeviceIdentifier() -> DeviceIdentifier {
        // 1. Try to grab from embedded.mobileprovision
        if let udid = grabUDIDFromProvisioningProfile() {
            return DeviceIdentifier(id: udid, isRealUDID: true)
        }

        // 2. Try reading from pairingFile.plist in the documents directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pairingFileURL = documentsURL.appendingPathComponent("pairingFile.plist")
        if FileManager.default.fileExists(atPath: pairingFileURL.path) {
            if let dict = NSDictionary(contentsOf: pairingFileURL) as? [String: Any] {
                // Check common keys for UDID in libimobiledevice pairing files
                let keys = ["UDID", "DeviceUDID", "UniqueDeviceID"]
                for key in keys {
                    if let udid = dict[key] as? String {
                        return DeviceIdentifier(id: udid, isRealUDID: true)
                    }
                }
            }
        }

        // 3. Fallback to identifierForVendor as a last resort
        let fallbackID = identifierForVendor?.uuidString ?? "Unknown"
        return DeviceIdentifier(id: fallbackID, isRealUDID: false)
    }

    func grabUDIDFromProvisioningProfile() -> String? {
        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            // The provisioning profile is a CMS signed message, but the XML is inside.
            // We search for the XML block.
            if let xmlStart = data.range(of: Data("<?xml".utf8)),
               let plistEnd = data.range(of: Data("</plist>".utf8)) {
                let xmlData = data.subdata(in: xmlStart.lowerBound..<plistEnd.upperBound)

                if let plist = try PropertyListSerialization.propertyList(from: xmlData, format: nil) as? [String: Any] {
                    if let devices = plist["ProvisionedDevices"] as? [String], !devices.isEmpty {
                        // If there's only one device, it's highly likely to be this one.
                        // If there are many, we can't be 100% sure, but returning the first one
                        // is better than nothing in this context.
                        return devices.first
                    }
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}
