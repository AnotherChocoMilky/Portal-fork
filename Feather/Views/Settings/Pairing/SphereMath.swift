import Foundation
import simd

// MARK: - Sphere Math
/// Utility functions for generating sphere points and performing 3D transforms.
enum SphereMath {

    // MARK: - Point Generation

    /// Returns `count` points evenly distributed on a unit sphere using the
    /// Fibonacci spiral algorithm — produces the perfectly ordered end state.
    static func fibonacciSpherePoints(count: Int) -> [SIMD3<Double>] {
        guard count > 1 else { return [SIMD3<Double>(0, 1, 0)] }
        let goldenRatio = (1.0 + sqrt(5.0)) / 2.0
        return (0..<count).map { i in
            let theta = acos(1.0 - 2.0 * Double(i) / Double(count - 1))
            let phi   = 2.0 * .pi * Double(i) / goldenRatio
            return SIMD3<Double>(
                sin(theta) * cos(phi),
                sin(theta) * sin(phi),
                cos(theta)
            )
        }
    }

    /// Returns `count` points scattered randomly on a unit sphere — the
    /// chaotic start state before morphing begins.
    static func randomSpherePoints(count: Int) -> [SIMD3<Double>] {
        var points: [SIMD3<Double>] = []
        points.reserveCapacity(count)
        while points.count < count {
            // Rejection sampling: keep only points inside the unit sphere,
            // then normalize — produces uniform distribution.
            let v = SIMD3<Double>(
                Double.random(in: -1...1),
                Double.random(in: -1...1),
                Double.random(in: -1...1)
            )
            let len = simd_length(v)
            guard len > 1e-6 else { continue }
            points.append(v / len)
        }
        return points
    }

    // MARK: - Projection

    /// Projects a unit-sphere 3D point onto a 2D canvas using perspective
    /// division.  Returns the canvas (x, y) coordinates and a `scale` factor
    /// (larger = closer to camera) suitable for depth-sorting and dot sizing.
    static func project(
        point: SIMD3<Double>,
        canvasSize: Double,
        cameraDistance: Double = 3.0
    ) -> (x: Double, y: Double, scale: Double) {
        let perspective = cameraDistance / (cameraDistance + point.z + 1.0)
        let half = canvasSize * 0.5
        let x = point.x * perspective * canvasSize * 0.4 + half
        let y = -point.y * perspective * canvasSize * 0.4 + half
        return (x, y, perspective)
    }

    // MARK: - Rotations

    /// Rotates `point` around the Y-axis by `angle` radians.
    static func rotateY(point: SIMD3<Double>, angle: Double) -> SIMD3<Double> {
        let c = cos(angle), s = sin(angle)
        return SIMD3<Double>(
             point.x * c + point.z * s,
             point.y,
            -point.x * s + point.z * c
        )
    }

    /// Rotates `point` around the X-axis by `angle` radians.
    static func rotateX(point: SIMD3<Double>, angle: Double) -> SIMD3<Double> {
        let c = cos(angle), s = sin(angle)
        return SIMD3<Double>(
            point.x,
            point.y * c - point.z * s,
            point.y * s + point.z * c
        )
    }

    /// Rotates `point` around the Z-axis by `angle` radians.
    static func rotateZ(point: SIMD3<Double>, angle: Double) -> SIMD3<Double> {
        let c = cos(angle), s = sin(angle)
        return SIMD3<Double>(
            point.x * c - point.y * s,
            point.x * s + point.y * c,
            point.z
        )
    }
}
