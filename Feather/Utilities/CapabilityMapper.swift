import Foundation

struct CapabilityInfo: Identifiable, Equatable {
    var id: String { key }
    let key: String
    let name: String
    let icon: String
}

enum CapabilityMapper {
    static func getInfo(for key: String) -> CapabilityInfo {
        switch key.lowercased() {
        case "armv7":
            return CapabilityInfo(key: key, name: "ARMv7", icon: "cpu")
        case "arm64":
            return CapabilityInfo(key: key, name: "ARM64", icon: "cpu.fill")
        case "gps":
            return CapabilityInfo(key: key, name: "GPS", icon: "location.fill")
        case "location-services":
            return CapabilityInfo(key: key, name: "Location Services", icon: "location")
        case "magnetic-compass":
            return CapabilityInfo(key: key, name: "Magnetometer", icon: "safari")
        case "accelerometer":
            return CapabilityInfo(key: key, name: "Accelerometer", icon: "gyroscope")
        case "gyroscope":
            return CapabilityInfo(key: key, name: "Gyroscope", icon: "gyroscope")
        case "wifi":
            return CapabilityInfo(key: key, name: "Wi-Fi", icon: "wifi")
        case "front-facing-camera":
            return CapabilityInfo(key: key, name: "Front Camera", icon: "camera")
        case "rear-facing-camera":
            return CapabilityInfo(key: key, name: "Rear Camera", icon: "camera.fill")
        case "video-camera":
            return CapabilityInfo(key: key, name: "Video Camera", icon: "video")
        case "autofocus-camera":
            return CapabilityInfo(key: key, name: "Autofocus", icon: "camera.viewfinder")
        case "still-camera":
            return CapabilityInfo(key: key, name: "Still Camera", icon: "photo")
        case "camera-flash":
            return CapabilityInfo(key: key, name: "Camera Flash", icon: "bolt.fill")
        case "telephony":
            return CapabilityInfo(key: key, name: "Telephony", icon: "phone.fill")
        case "sms":
            return CapabilityInfo(key: key, name: "SMS", icon: "message.fill")
        case "bluetooth-le":
            return CapabilityInfo(key: key, name: "Bluetooth LE", icon: "bolt.bluetooth.fill")
        case "nfc":
            return CapabilityInfo(key: key, name: "NFC", icon: "wave.3.right")
        case "gamekit":
            return CapabilityInfo(key: key, name: "GameKit", icon: "gamecontroller")
        case "microphone":
            return CapabilityInfo(key: key, name: "Microphone", icon: "mic.fill")
        case "healthkit":
            return CapabilityInfo(key: key, name: "HealthKit", icon: "heart.fill")
        case "homekit":
            return CapabilityInfo(key: key, name: "HomeKit", icon: "house.fill")
        case "metal":
            return CapabilityInfo(key: key, name: "Metal", icon: "sparkles")
        case "arkit":
            return CapabilityInfo(key: key, name: "ARKit", icon: "arkit")
        case "peer-to-peer":
            return CapabilityInfo(key: key, name: "Peer-to-Peer", icon: "personalhotspot")
        case "inter-app-audio":
            return CapabilityInfo(key: key, name: "Inter-App Audio", icon: "waveform")
        default:
            return CapabilityInfo(key: key, name: key, icon: "questionmark.circle")
        }
    }
}
