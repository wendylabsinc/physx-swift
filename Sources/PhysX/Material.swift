/// Surface coefficients used when creating PhysX materials.
public struct Material: Codable, Hashable, Sendable {
    /// Static friction coefficient.
    public var staticFriction: Float

    /// Dynamic friction coefficient.
    public var dynamicFriction: Float

    /// Restitution coefficient in the range `0...1`.
    public var restitution: Float

    /// Creates material coefficients.
    public init(staticFriction: Float = 0.5, dynamicFriction: Float = 0.5, restitution: Float = 0) {
        self.staticFriction = staticFriction
        self.dynamicFriction = dynamicFriction
        self.restitution = restitution
    }

    /// The default PhysX-style material coefficients.
    public static let `default` = Material()

    /// Validates the material coefficients before handing them to a backend.
    public func validate() throws {
        guard staticFriction.isFinite, dynamicFriction.isFinite, restitution.isFinite else {
            throw PhysicsError.validation("Material coefficients must be finite.")
        }
        guard staticFriction >= 0, dynamicFriction >= 0 else {
            throw PhysicsError.validation("Friction coefficients must be non-negative.")
        }
        guard restitution >= 0, restitution <= 1 else {
            throw PhysicsError.validation("Restitution must be between 0 and 1.")
        }
    }
}
