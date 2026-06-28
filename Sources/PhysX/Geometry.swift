/// A collision geometry supported by the SDK bridge.
public enum Geometry: Codable, Hashable, Sendable {
    /// An infinite plane represented by a normal and distance from the origin.
    case plane(normal: Vector3 = .unitY, distance: Float = 0)

    /// A sphere with the given radius.
    case sphere(radius: Float)

    /// An axis-aligned box represented by half extents.
    case box(halfExtents: Vector3)

    /// A capsule aligned to the local x-axis, matching PhysX capsule geometry.
    case capsule(radius: Float, halfHeight: Float)

    /// Validates geometry parameters before creating backend objects.
    public func validate(for kind: BodyKind) throws {
        switch self {
        case let .plane(normal, distance):
            guard normal.isFinite, distance.isFinite else {
                throw PhysicsError.validation("Plane geometry must be finite.")
            }
            guard normal.length > 1e-6 else {
                throw PhysicsError.validation("Plane normal must have non-zero length.")
            }
            guard kind == .static else {
                throw PhysicsError.validation("Plane geometry can only be used with static bodies.")
            }
        case let .sphere(radius):
            try validatePositive(radius, named: "Sphere radius")
        case let .box(halfExtents):
            guard halfExtents.isFinite else {
                throw PhysicsError.validation("Box half extents must be finite.")
            }
            guard halfExtents.x > 0, halfExtents.y > 0, halfExtents.z > 0 else {
                throw PhysicsError.validation("Box half extents must be positive.")
            }
        case let .capsule(radius, halfHeight):
            try validatePositive(radius, named: "Capsule radius")
            try validatePositive(halfHeight, named: "Capsule half height")
        }
    }

    private func validatePositive(_ value: Float, named name: String) throws {
        guard value.isFinite else {
            throw PhysicsError.validation("\(name) must be finite.")
        }
        guard value > 0 else {
            throw PhysicsError.validation("\(name) must be positive.")
        }
    }
}
