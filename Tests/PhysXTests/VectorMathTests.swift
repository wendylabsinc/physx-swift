import Testing
@testable import PhysX

@Suite("Vector math")
struct VectorMathTests {
    @Test("Vector arithmetic is component-wise")
    func vectorArithmetic() {
        #expect(Vector3(x: 1, y: 2, z: 3) + Vector3(x: 4, y: 5, z: 6) == Vector3(x: 5, y: 7, z: 9))
        #expect(Vector3(x: 4, y: 5, z: 6) - Vector3(x: 1, y: 2, z: 3) == Vector3(x: 3, y: 3, z: 3))
        #expect(Vector3(x: 1, y: -2, z: 3) * 2 == Vector3(x: 2, y: -4, z: 6))
        #expect(Vector3(x: 2, y: -4, z: 6) / 2 == Vector3(x: 1, y: -2, z: 3))
    }

    @Test("Dot, cross, and normalization match right-handed coordinates")
    func vectorProducts() {
        #expect(Vector3.unitX.dot(.unitY) == 0)
        #expect(Vector3.unitX.cross(.unitY) == .unitZ)
        #expect(Vector3(x: 3, y: 0, z: 4).length == 5)
        #expect(Vector3(x: 0, y: 3, z: 0).normalized() == .unitY)
        #expect(Vector3.zero.normalized() == .zero)
    }

    @Test("Quaternion multiplication preserves identity")
    func quaternionIdentity() {
        let rotation = Quaternion(angleRadians: .pi / 2, axis: .unitY).normalized()
        #expect((Quaternion.identity * rotation).normalized() == rotation)
        #expect((rotation * Quaternion.identity).normalized() == rotation)
    }
}
