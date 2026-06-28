/// A stable handle for a body inside a physics world.
public struct RigidBodyID: Codable, Hashable, Sendable, Comparable, CustomStringConvertible {
    /// The backend-unique raw value.
    public let rawValue: UInt64

    /// Creates an ID from a raw value.
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    /// A concise debug description.
    public var description: String {
        "RigidBodyID(\(rawValue))"
    }

    /// Orders IDs by raw value.
    public static func < (lhs: RigidBodyID, rhs: RigidBodyID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A snapshot of a body's observable state.
public struct RigidBodyState: Codable, Hashable, Sendable {
    /// Body identifier.
    public var id: RigidBodyID

    /// Original body category.
    public var kind: BodyKind

    /// Current transform.
    public var transform: Transform

    /// Current linear velocity.
    public var linearVelocity: Vector3

    /// Current angular velocity.
    public var angularVelocity: Vector3

    /// Creates a body state value.
    public init(
        id: RigidBodyID,
        kind: BodyKind,
        transform: Transform,
        linearVelocity: Vector3,
        angularVelocity: Vector3
    ) {
        self.id = id
        self.kind = kind
        self.transform = transform
        self.linearVelocity = linearVelocity
        self.angularVelocity = angularVelocity
    }
}

/// A backend-neutral physics world interface.
public protocol PhysicsWorld {
    /// Adds a rigid body and returns its world-local identifier.
    @discardableResult
    func addRigidBody(_ descriptor: RigidBodyDescriptor) throws -> RigidBodyID

    /// Removes a rigid body from the world.
    func removeRigidBody(_ id: RigidBodyID) throws

    /// Returns the current transform for a body.
    func transform(of id: RigidBodyID) throws -> Transform

    /// Sets the current transform for a body.
    func setTransform(_ transform: Transform, for id: RigidBodyID) throws

    /// Returns the current linear velocity for a body.
    func linearVelocity(of id: RigidBodyID) throws -> Vector3

    /// Sets the current linear velocity for a body.
    func setLinearVelocity(_ velocity: Vector3, for id: RigidBodyID) throws

    /// Advances the simulation by a positive time step in seconds.
    func step(_ timeStep: Float) throws

    /// Returns all observable body states in deterministic ID order.
    func snapshot() throws -> [RigidBodyState]
}
