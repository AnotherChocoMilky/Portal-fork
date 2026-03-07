import Foundation
import simd

// MARK: - Dot
/// A single dot in the 3D morphing sphere.
/// Interpolates from a random chaotic position (`startPos`) to a
/// Fibonacci-sphere position (`endPos`) based on a morph progress value.
struct Dot {
    /// Initial (chaotic) position on the unit sphere.
    var startPos: SIMD3<Double>
    /// Final (ordered) Fibonacci-sphere position on the unit sphere.
    var endPos: SIMD3<Double>

    // MARK: - Interpolation

    /// Returns the dot's 3D position linearly interpolated between
    /// `startPos` and `endPos` at the given morph `progress` (0…1).
    func interpolated(progress: Double) -> SIMD3<Double> {
        let t = Swift.max(0.0, Swift.min(1.0, progress))
        return startPos + (endPos - startPos) * t
    }
}
