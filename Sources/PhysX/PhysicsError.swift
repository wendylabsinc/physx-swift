/// Errors produced by SDK validation or backend operations.
public enum PhysicsError: Error, Equatable, Sendable, CustomStringConvertible {
    /// The caller supplied an invalid descriptor or simulation parameter.
    case validation(String)

    /// The requested body ID is not present in the world.
    case bodyNotFound(RigidBodyID)

    /// A native or custom backend failed.
    case backend(String)

    /// A readable error message.
    public var description: String {
        switch self {
        case let .validation(message):
            return message
        case let .bodyNotFound(id):
            return "Rigid body \(id.rawValue) was not found."
        case let .backend(message):
            return message
        }
    }
}
