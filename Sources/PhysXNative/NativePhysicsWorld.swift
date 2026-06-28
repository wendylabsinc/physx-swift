import CPhysX
import PhysX

/// A `PhysicsWorld` implementation backed by native NVIDIA PhysX.
public final class NativePhysicsWorld: PhysicsWorld {
    private var world: OpaquePointer?

    /// Creates a native PhysX world from a scene descriptor.
    public init(scene: SceneDescriptor = SceneDescriptor()) throws {
        try scene.validate()
        var status = PhysXSwiftStatus()
        var createdWorld: OpaquePointer?
        let result = physx_swift_world_create(scene.cValue, &createdWorld, &status)
        try Self.throwIfNeeded(result, status)
        world = createdWorld
    }

    deinit {
        physx_swift_world_destroy(world)
    }

    /// Adds a rigid body and returns its world-local identifier.
    @discardableResult
    public func addRigidBody(_ descriptor: RigidBodyDescriptor) throws -> RigidBodyID {
        try descriptor.validate()
        var status = PhysXSwiftStatus()
        var rawID: UInt64 = 0
        let result = try physx_swift_world_add_rigid_body(requiredWorld(), descriptor.cValue, &rawID, &status)
        try Self.throwIfNeeded(result, status)
        return RigidBodyID(rawValue: rawID)
    }

    /// Removes a rigid body from the native scene.
    public func removeRigidBody(_ id: RigidBodyID) throws {
        var status = PhysXSwiftStatus()
        let result = try physx_swift_world_remove_rigid_body(requiredWorld(), id.rawValue, &status)
        try Self.throwIfNeeded(result, status)
    }

    /// Returns the current native transform for a body.
    public func transform(of id: RigidBodyID) throws -> Transform {
        var status = PhysXSwiftStatus()
        var transform = PhysXSwiftTransform()
        let result = try physx_swift_world_get_transform(requiredWorld(), id.rawValue, &transform, &status)
        try Self.throwIfNeeded(result, status)
        return Transform(transform)
    }

    /// Sets the current native transform for a body.
    public func setTransform(_ transform: Transform, for id: RigidBodyID) throws {
        guard transform.isFinite else {
            throw PhysicsError.validation("Rigid body transform must be finite.")
        }
        var status = PhysXSwiftStatus()
        let result = try physx_swift_world_set_transform(requiredWorld(), id.rawValue, transform.cValue, &status)
        try Self.throwIfNeeded(result, status)
    }

    /// Returns the current native linear velocity for a body.
    public func linearVelocity(of id: RigidBodyID) throws -> Vector3 {
        var status = PhysXSwiftStatus()
        var velocity = PhysXSwiftVector3()
        let result = try physx_swift_world_get_linear_velocity(requiredWorld(), id.rawValue, &velocity, &status)
        try Self.throwIfNeeded(result, status)
        return Vector3(velocity)
    }

    /// Sets the current native linear velocity for a dynamic or kinematic body.
    public func setLinearVelocity(_ velocity: Vector3, for id: RigidBodyID) throws {
        guard velocity.isFinite else {
            throw PhysicsError.validation("Linear velocity must be finite.")
        }
        var status = PhysXSwiftStatus()
        let result = try physx_swift_world_set_linear_velocity(requiredWorld(), id.rawValue, velocity.cValue, &status)
        try Self.throwIfNeeded(result, status)
    }

    /// Advances the native PhysX simulation by a positive time step in seconds.
    public func step(_ timeStep: Float) throws {
        var status = PhysXSwiftStatus()
        let result = try physx_swift_world_step(requiredWorld(), timeStep, &status)
        try Self.throwIfNeeded(result, status)
    }

    /// Native snapshots are intentionally not implemented until the C shim exposes actor enumeration.
    public func snapshot() throws -> [RigidBodyState] {
        throw PhysicsError.backend("Native snapshot enumeration is not implemented by the current C bridge.")
    }

    private func requiredWorld() throws -> OpaquePointer {
        guard let world else {
            throw PhysicsError.backend("Native PhysX world has been destroyed.")
        }
        return world
    }

    private static func throwIfNeeded(_ result: Int32, _ status: PhysXSwiftStatus) throws {
        guard result == 0 else {
            throw PhysicsError.backend(status.messageString)
        }
    }
}

private extension PhysXSwiftStatus {
    var messageString: String {
        withUnsafePointer(to: message) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 256) {
                String(cString: $0)
            }
        }
    }
}

private extension SceneDescriptor {
    var cValue: PhysXSwiftSceneDescriptor {
        PhysXSwiftSceneDescriptor(gravity: gravity.cValue, workerThreadCount: Int32(workerThreadCount))
    }
}

private extension RigidBodyDescriptor {
    var cValue: PhysXSwiftRigidBodyDescriptor {
        PhysXSwiftRigidBodyDescriptor(
            kind: kind.cValue,
            transform: transform.cValue,
            geometry: geometry.cValue,
            material: material.cValue,
            density: density,
            linearVelocity: linearVelocity.cValue,
            angularVelocity: angularVelocity.cValue
        )
    }
}

private extension BodyKind {
    var cValue: PhysXSwiftBodyKind {
        switch self {
        case .static:
            return PhysXSwiftBodyKindStatic
        case .dynamic:
            return PhysXSwiftBodyKindDynamic
        case .kinematic:
            return PhysXSwiftBodyKindKinematic
        }
    }
}

private extension Geometry {
    var cValue: PhysXSwiftGeometry {
        switch self {
        case let .plane(normal, distance):
            return PhysXSwiftGeometry(kind: PhysXSwiftGeometryKindPlane, vector: normal.cValue, radius: 0, halfHeight: 0, distance: distance)
        case let .sphere(radius):
            return PhysXSwiftGeometry(kind: PhysXSwiftGeometryKindSphere, vector: .init(), radius: radius, halfHeight: 0, distance: 0)
        case let .box(halfExtents):
            return PhysXSwiftGeometry(kind: PhysXSwiftGeometryKindBox, vector: halfExtents.cValue, radius: 0, halfHeight: 0, distance: 0)
        case let .capsule(radius, halfHeight):
            return PhysXSwiftGeometry(kind: PhysXSwiftGeometryKindCapsule, vector: .init(), radius: radius, halfHeight: halfHeight, distance: 0)
        }
    }
}

private extension Material {
    var cValue: PhysXSwiftMaterial {
        PhysXSwiftMaterial(staticFriction: staticFriction, dynamicFriction: dynamicFriction, restitution: restitution)
    }
}

private extension Transform {
    init(_ cValue: PhysXSwiftTransform) {
        self.init(position: Vector3(cValue.position), rotation: Quaternion(cValue.rotation))
    }

    var cValue: PhysXSwiftTransform {
        PhysXSwiftTransform(position: position.cValue, rotation: rotation.cValue)
    }
}

private extension Vector3 {
    init(_ cValue: PhysXSwiftVector3) {
        self.init(x: cValue.x, y: cValue.y, z: cValue.z)
    }

    var cValue: PhysXSwiftVector3 {
        PhysXSwiftVector3(x: x, y: y, z: z)
    }
}

private extension Quaternion {
    init(_ cValue: PhysXSwiftQuaternion) {
        self.init(x: cValue.x, y: cValue.y, z: cValue.z, w: cValue.w)
    }

    var cValue: PhysXSwiftQuaternion {
        PhysXSwiftQuaternion(x: x, y: y, z: z, w: w)
    }
}
