/// A three-dimensional vector using PhysX-compatible `Float` components.
public struct Vector3: Codable, Hashable, Sendable, CustomStringConvertible, ExpressibleByArrayLiteral {
    /// The x-axis component.
    public var x: Float

    /// The y-axis component.
    public var y: Float

    /// The z-axis component.
    public var z: Float

    /// Creates a vector from explicit components.
    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// Creates a vector from an array literal containing exactly three components.
    public init(arrayLiteral elements: Float...) {
        precondition(elements.count == 3, "Vector3 array literals must contain exactly three Float values.")
        self.init(x: elements[0], y: elements[1], z: elements[2])
    }

    /// A vector with all components set to zero.
    public static let zero = Vector3(x: 0, y: 0, z: 0)

    /// The positive x-axis unit vector.
    public static let unitX = Vector3(x: 1, y: 0, z: 0)

    /// The positive y-axis unit vector.
    public static let unitY = Vector3(x: 0, y: 1, z: 0)

    /// The positive z-axis unit vector.
    public static let unitZ = Vector3(x: 0, y: 0, z: 1)

    /// Returns true when every component is finite.
    public var isFinite: Bool {
        x.isFinite && y.isFinite && z.isFinite
    }

    /// The squared Euclidean length.
    public var lengthSquared: Float {
        dot(self)
    }

    /// The Euclidean length.
    public var length: Float {
        lengthSquared.squareRoot()
    }

    /// A concise debug description.
    public var description: String {
        "Vector3(x: \(x), y: \(y), z: \(z))"
    }

    /// Returns the dot product with another vector.
    public func dot(_ other: Vector3) -> Float {
        x * other.x + y * other.y + z * other.z
    }

    /// Returns the cross product with another vector.
    public func cross(_ other: Vector3) -> Vector3 {
        Vector3(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }

    /// Returns a normalized vector, or zero when the length is too small.
    public func normalized(epsilon: Float = 1e-6) -> Vector3 {
        let magnitude = length
        guard magnitude > epsilon else {
            return .zero
        }
        return self / magnitude
    }

    /// Adds two vectors component-wise.
    public static func + (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    /// Subtracts two vectors component-wise.
    public static func - (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    /// Negates each component.
    public static prefix func - (value: Vector3) -> Vector3 {
        Vector3(x: -value.x, y: -value.y, z: -value.z)
    }

    /// Scales a vector by a scalar.
    public static func * (lhs: Vector3, rhs: Float) -> Vector3 {
        Vector3(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }

    /// Scales a vector by a scalar.
    public static func * (lhs: Float, rhs: Vector3) -> Vector3 {
        rhs * lhs
    }

    /// Divides a vector by a scalar.
    public static func / (lhs: Vector3, rhs: Float) -> Vector3 {
        Vector3(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs)
    }
}
