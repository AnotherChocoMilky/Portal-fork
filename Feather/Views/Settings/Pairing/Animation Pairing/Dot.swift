import Foundation
import simd

struct Dot {
    var startPos: SIMD3<Double>
    var endPos: SIMD3<Double>

    func interpolated(progress: Double) -> SIMD3<Double> {
        let t = Swift.max(0.0, Swift.min(1.0, progress))
        return startPos + (endPos - startPos) * t
    }
}
