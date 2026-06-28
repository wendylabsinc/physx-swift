/// A deterministic reference backend for validation, tests, and tools.
///
/// This backend intentionally does not implement PhysX collision solving. It applies gravity to
/// dynamic bodies, moves kinematic bodies by their explicit velocity, and keeps static bodies fixed.
public final class InMemoryPhysicsWorld: PhysicsWorld {
    private struct BodyRecord {
        var descriptor: RigidBodyDescriptor
        var transform: Transform
        var linearVelocity: Vector3
        var angularVelocity: Vector3
    }

    private var scene: SceneDescriptor
    private var nextID: UInt64 = 1
    private var bodies: [RigidBodyID: BodyRecord] = [:]

    /// Creates an in-memory world.
    public init(scene: SceneDescriptor = SceneDescriptor()) throws {
        try scene.validate()
        self.scene = scene
    }

    /// Adds a rigid body and returns its world-local identifier.
    @discardableResult
    public func addRigidBody(_ descriptor: RigidBodyDescriptor) throws -> RigidBodyID {
        try descriptor.validate()
        let id = RigidBodyID(rawValue: nextID)
        nextID += 1
        bodies[id] = BodyRecord(
            descriptor: descriptor,
            transform: descriptor.transform,
            linearVelocity: descriptor.linearVelocity,
            angularVelocity: descriptor.angularVelocity
        )
        return id
    }

    /// Removes a rigid body from the world.
    public func removeRigidBody(_ id: RigidBodyID) throws {
        guard bodies.removeValue(forKey: id) != nil else {
            throw PhysicsError.bodyNotFound(id)
        }
    }

    /// Returns the current transform for a body.
    public func transform(of id: RigidBodyID) throws -> Transform {
        try record(for: id).transform
    }

    /// Sets the current transform for a body.
    public func setTransform(_ transform: Transform, for id: RigidBodyID) throws {
        guard transform.isFinite else {
            throw PhysicsError.validation("Rigid body transform must be finite.")
        }
        try update(id) { record in
            record.transform = transform
        }
    }

    /// Returns the current linear velocity for a body.
    public func linearVelocity(of id: RigidBodyID) throws -> Vector3 {
        try record(for: id).linearVelocity
    }

    /// Sets the current linear velocity for a body.
    public func setLinearVelocity(_ velocity: Vector3, for id: RigidBodyID) throws {
        guard velocity.isFinite else {
            throw PhysicsError.validation("Linear velocity must be finite.")
        }
        try update(id) { record in
            record.linearVelocity = velocity
        }
    }

    /// Advances the reference simulation by a positive time step in seconds.
    public func step(_ timeStep: Float) throws {
        guard timeStep.isFinite, timeStep > 0 else {
            throw PhysicsError.validation("Time step must be positive and finite.")
        }

        for id in bodies.keys {
            guard var record = bodies[id] else {
                continue
            }

            switch record.descriptor.kind {
            case .static:
                break
            case .dynamic:
                record.linearVelocity = record.linearVelocity + scene.gravity * timeStep
                record.transform.position = record.transform.position + record.linearVelocity * timeStep
            case .kinematic:
                record.transform.position = record.transform.position + record.linearVelocity * timeStep
            }

            bodies[id] = record
        }
    }

    /// Returns all observable body states in deterministic ID order.
    public func snapshot() throws -> [RigidBodyState] {
        bodies.keys.sorted().compactMap { id in
            guard let record = bodies[id] else {
                return nil
            }
            return RigidBodyState(
                id: id,
                kind: record.descriptor.kind,
                transform: record.transform,
                linearVelocity: record.linearVelocity,
                angularVelocity: record.angularVelocity
            )
        }
    }

    private func record(for id: RigidBodyID) throws -> BodyRecord {
        guard let record = bodies[id] else {
            throw PhysicsError.bodyNotFound(id)
        }
        return record
    }

    private func update(_ id: RigidBodyID, _ body: (inout BodyRecord) -> Void) throws {
        guard var record = bodies[id] else {
            throw PhysicsError.bodyNotFound(id)
        }
        body(&record)
        bodies[id] = record
    }
}
