import Testing
@testable import PhysX

@Suite("In-memory physics world")
struct InMemoryPhysicsWorldTests {
    @Test("IDs are stable, unique, and snapshots are sorted")
    func idsAndSnapshots() throws {
        let world = try InMemoryPhysicsWorld()

        let first = try world.addRigidBody(.init(kind: .static, geometry: .box(halfExtents: [1, 1, 1])))
        let second = try world.addRigidBody(.init(kind: .dynamic, geometry: .sphere(radius: 1)))

        #expect(first.rawValue == 1)
        #expect(second.rawValue == 2)
        #expect(try world.snapshot().map(\.id) == [first, second])
    }

    @Test("Dynamic bodies integrate gravity and velocity")
    func dynamicIntegration() throws {
        let world = try InMemoryPhysicsWorld(scene: .init(gravity: [0, -10, 0]))
        let body = try world.addRigidBody(.init(
            kind: .dynamic,
            transform: .init(position: [0, 10, 0]),
            geometry: .sphere(radius: 1),
            linearVelocity: [1, 0, 0]
        ))

        try world.step(0.5)

        let transform = try world.transform(of: body)
        let velocity = try world.linearVelocity(of: body)
        #expect(transform.position == Vector3(x: 0.5, y: 7.5, z: 0))
        #expect(velocity == Vector3(x: 1, y: -5, z: 0))
    }

    @Test("Static bodies remain fixed while kinematic bodies follow explicit velocity")
    func staticAndKinematicBehavior() throws {
        let world = try InMemoryPhysicsWorld(scene: .init(gravity: [0, -10, 0]))
        let staticBody = try world.addRigidBody(.init(
            kind: .static,
            transform: .init(position: [0, 2, 0]),
            geometry: .box(halfExtents: [1, 1, 1])
        ))
        let kinematicBody = try world.addRigidBody(.init(
            kind: .kinematic,
            transform: .init(position: [0, 2, 0]),
            geometry: .box(halfExtents: [1, 1, 1]),
            linearVelocity: [0, 3, 0]
        ))

        try world.step(2)

        #expect(try world.transform(of: staticBody).position == Vector3(x: 0, y: 2, z: 0))
        #expect(try world.transform(of: kinematicBody).position == Vector3(x: 0, y: 8, z: 0))
        #expect(try world.linearVelocity(of: kinematicBody) == Vector3(x: 0, y: 3, z: 0))
    }

    @Test("Body mutation validates target IDs and values")
    func mutationErrors() throws {
        let world = try InMemoryPhysicsWorld()
        let body = try world.addRigidBody(.init(kind: .dynamic, geometry: .sphere(radius: 1)))
        let missing = RigidBodyID(rawValue: 999)

        try world.setTransform(.init(position: [1, 2, 3]), for: body)
        #expect(try world.transform(of: body).position == Vector3(x: 1, y: 2, z: 3))

        #expect(throws: PhysicsError.self) {
            try world.transform(of: missing)
        }

        #expect(throws: PhysicsError.self) {
            try world.setLinearVelocity(Vector3(x: .nan, y: 0, z: 0), for: body)
        }

        try world.removeRigidBody(body)
        #expect(try world.snapshot().isEmpty)
    }

    @Test("Step rejects non-positive or non-finite time")
    func stepValidation() throws {
        let world = try InMemoryPhysicsWorld()

        #expect(throws: PhysicsError.self) {
            try world.step(0)
        }

        #expect(throws: PhysicsError.self) {
            try world.step(.infinity)
        }
    }
}
