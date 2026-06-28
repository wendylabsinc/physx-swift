/// A rigid transform made from a translation and orientation.
public struct Transform: Codable, Hashable, Sendable, CustomStringConvertible {
    /// The world-space position.
    public var position: Vector3

    /// The world-space orientation.
    public var rotation: Quaternion

    /// Creates a transform.
    public init(position: Vector3 = .zero, rotation: Quaternion = .identity) {
        self.position = position
        self.rotation = rotation
    }

    /// The identity transform.
    public static let identity = Transform()

    /// Returns true when all components are finite.
    public var isFinite: Bool {
        position.isFinite && rotation.isFinite
    }

    /// A concise debug description.
    public var description: String {
        "Transform(position: \(position), rotation: \(rotation))"
    }
}
