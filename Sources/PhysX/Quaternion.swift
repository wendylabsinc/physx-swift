import Foundation

/// A unit quaternion used to represent orientation.
public struct Quaternion: Codable, Hashable, Sendable, CustomStringConvertible {
    /// The x component of the imaginary vector.
    public var x: Float

    /// The y component of the imaginary vector.
    public var y: Float

    /// The z component of the imaginary vector.
    public var z: Float

    /// The real component.
    public var w: Float

    /// Creates a quaternion from raw components.
    public init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    /// Creates a rotation around an axis.
    public init(angleRadians: Float, axis: Vector3) {
        let normalizedAxis = axis.normalized()
        let halfAngle = angleRadians * 0.5
        let sine = sin(halfAngle)
        self.init(
            x: normalizedAxis.x * sine,
            y: normalizedAxis.y * sine,
            z: normalizedAxis.z * sine,
            w: cos(halfAngle)
        )
    }

    /// The identity rotation.
    public static let identity = Quaternion(x: 0, y: 0, z: 0, w: 1)

    /// Returns true when every component is finite.
    public var isFinite: Bool {
        x.isFinite && y.isFinite && z.isFinite && w.isFinite
    }

    /// The squared magnitude.
    public var lengthSquared: Float {
        x * x + y * y + z * z + w * w
    }

    /// The magnitude.
    public var length: Float {
        lengthSquared.squareRoot()
    }

    /// A concise debug description.
    public var description: String {
        "Quaternion(x: \(x), y: \(y), z: \(z), w: \(w))"
    }

    /// Returns a normalized quaternion, or identity when the magnitude is too small.
    public func normalized(epsilon: Float = 1e-6) -> Quaternion {
        let magnitude = length
        guard magnitude > epsilon else {
            return .identity
        }
        return Quaternion(x: x / magnitude, y: y / magnitude, z: z / magnitude, w: w / magnitude)
    }

    /// Concatenates two rotations.
    public static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        Quaternion(
            x: lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            y: lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
            z: lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w,
            w: lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z
        )
    }
}
