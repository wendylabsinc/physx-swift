/// The backend actor category used for a rigid body.
public enum BodyKind: String, Codable, Hashable, Sendable {
    /// An immovable body.
    case `static`

    /// A simulated body affected by gravity and forces.
    case dynamic

    /// A body moved by the application but represented as a dynamic actor in PhysX.
    case kinematic
}

/// Scene-level settings used when creating a physics world.
public struct SceneDescriptor: Codable, Hashable, Sendable {
    /// Scene gravity in world units per second squared.
    public var gravity: Vector3

    /// Number of worker threads requested by native PhysX dispatchers.
    public var workerThreadCount: Int

    /// Creates scene settings.
    public init(gravity: Vector3 = Vector3(x: 0, y: -9.81, z: 0), workerThreadCount: Int = 1) {
        self.gravity = gravity
        self.workerThreadCount = workerThreadCount
    }

    /// Validates scene settings.
    public func validate() throws {
        guard gravity.isFinite else {
            throw PhysicsError.validation("Scene gravity must be finite.")
        }
        guard workerThreadCount >= 0 else {
            throw PhysicsError.validation("Worker thread count must be non-negative.")
        }
    }
}

/// A rigid body creation request.
public struct RigidBodyDescriptor: Codable, Hashable, Sendable {
    /// Optional application-facing label.
    public var name: String?

    /// Static, dynamic, or kinematic behavior.
    public var kind: BodyKind

    /// Initial transform.
    public var transform: Transform

    /// Collision geometry.
    public var geometry: Geometry

    /// Surface material.
    public var material: Material

    /// Density used by native PhysX to derive mass and inertia for dynamic bodies.
    public var density: Float

    /// Initial linear velocity.
    public var linearVelocity: Vector3

    /// Initial angular velocity.
    public var angularVelocity: Vector3

    /// Creates a rigid body descriptor.
    public init(
        name: String? = nil,
        kind: BodyKind,
        transform: Transform = .identity,
        geometry: Geometry,
        material: Material = .default,
        density: Float = 1,
        linearVelocity: Vector3 = .zero,
        angularVelocity: Vector3 = .zero
    ) {
        self.name = name
        self.kind = kind
        self.transform = transform
        self.geometry = geometry
        self.material = material
        self.density = density
        self.linearVelocity = linearVelocity
        self.angularVelocity = angularVelocity
    }

    /// Validates all descriptor fields before creating a backend body.
    public func validate() throws {
        guard transform.isFinite else {
            throw PhysicsError.validation("Rigid body transform must be finite.")
        }
        guard linearVelocity.isFinite, angularVelocity.isFinite else {
            throw PhysicsError.validation("Rigid body velocities must be finite.")
        }
        try geometry.validate(for: kind)
        try material.validate()
        if kind != .static {
            guard density.isFinite, density > 0 else {
                throw PhysicsError.validation("Dynamic and kinematic bodies require a positive finite density.")
            }
        }
    }
}
