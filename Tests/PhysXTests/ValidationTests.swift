import Testing
@testable import PhysX

@Suite("Descriptor validation")
struct ValidationTests {
    @Test("Scene rejects invalid gravity and worker count")
    func sceneValidation() throws {
        try SceneDescriptor().validate()

        #expect(throws: PhysicsError.self) {
            try SceneDescriptor(gravity: Vector3(x: .nan, y: 0, z: 0)).validate()
        }

        #expect(throws: PhysicsError.self) {
            try SceneDescriptor(workerThreadCount: -1).validate()
        }
    }

    @Test("Material rejects non-finite and out-of-range coefficients")
    func materialValidation() throws {
        try Material.default.validate()

        #expect(throws: PhysicsError.self) {
            try Material(staticFriction: -0.1).validate()
        }

        #expect(throws: PhysicsError.self) {
            try Material(restitution: 1.1).validate()
        }
    }

    @Test("Geometry validation enforces PhysX-compatible shapes")
    func geometryValidation() throws {
        try Geometry.sphere(radius: 1).validate(for: .dynamic)
        try Geometry.box(halfExtents: [1, 2, 3]).validate(for: .static)
        try Geometry.capsule(radius: 0.5, halfHeight: 1).validate(for: .kinematic)
        try Geometry.plane(normal: .unitY, distance: 0).validate(for: .static)

        #expect(throws: PhysicsError.self) {
            try Geometry.sphere(radius: 0).validate(for: .dynamic)
        }

        #expect(throws: PhysicsError.self) {
            try Geometry.box(halfExtents: [1, 0, 1]).validate(for: .dynamic)
        }

        #expect(throws: PhysicsError.self) {
            try Geometry.plane(normal: .zero, distance: 0).validate(for: .static)
        }

        #expect(throws: PhysicsError.self) {
            try Geometry.plane(normal: .unitY, distance: 0).validate(for: .dynamic)
        }
    }

    @Test("Rigid bodies validate velocities, transforms, and density")
    func rigidBodyValidation() throws {
        let valid = RigidBodyDescriptor(kind: .dynamic, geometry: .sphere(radius: 1))
        try valid.validate()

        #expect(throws: PhysicsError.self) {
            try RigidBodyDescriptor(
                kind: .dynamic,
                transform: Transform(position: Vector3(x: 0, y: .infinity, z: 0)),
                geometry: .sphere(radius: 1)
            ).validate()
        }

        #expect(throws: PhysicsError.self) {
            try RigidBodyDescriptor(kind: .dynamic, geometry: .sphere(radius: 1), density: 0).validate()
        }

        try RigidBodyDescriptor(kind: .static, geometry: .box(halfExtents: [1, 1, 1]), density: 0).validate()
    }
}
