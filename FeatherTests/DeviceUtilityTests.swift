import XCTest
@testable import Feather

class DeviceUtilityTests: XCTestCase {

    func testExtractUDIDFromProvisioningXML() {
        let mockXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>ProvisionedDevices</key>
            <array>
                <string>00008101-000A1A1A1A1A1A1A</string>
                <string>12345678-9ABC-DEF0-1234-56789ABCDEF0</string>
            </array>
        </dict>
        </plist>
        """

        guard let data = mockXML.data(using: .utf8) else {
            XCTFail("Failed to create data from mock XML")
            return
        }

        // We simulate the logic in grabUDIDFromProvisioningProfile
        do {
            if let xmlStart = data.range(of: Data("<?xml".utf8)),
               let plistEnd = data.range(of: Data("</plist>".utf8)) {
                let xmlData = data.subdata(in: xmlStart.lowerBound..<plistEnd.upperBound)

                if let plist = try PropertyListSerialization.propertyList(from: xmlData, format: nil) as? [String: Any] {
                    if let devices = plist["ProvisionedDevices"] as? [String], !devices.isEmpty {
                        XCTAssertEqual(devices.first, "00008101-000A1A1A1A1A1A1A")
                        return
                    }
                }
            }
        } catch {
            XCTFail("Failed to parse plist: \(error)")
        }

        XCTFail("UDID not found in mock XML")
    }
}
