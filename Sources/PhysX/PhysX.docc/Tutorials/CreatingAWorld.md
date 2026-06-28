# Creating a World

Create a Swift world by choosing a backend and passing shared descriptors.

## Overview

The core `PhysX` module includes `InMemoryPhysicsWorld`, a small deterministic
backend for tests and editor tooling. It validates the same descriptor types
used by the native bridge.

```swift
import PhysX

let world = try InMemoryPhysicsWorld(scene: .init(gravity: [0, -9.81, 0]))

let ball = try world.addRigidBody(.init(
    name: "ball",
    kind: .dynamic,
    transform: .init(position: [0, 4, 0]),
    geometry: .sphere(radius: 0.25),
    material: .default,
    density: 1
))

try world.step(1.0 / 60.0)
let currentTransform = try world.transform(of: ball)
```

When `PHYSX_SWIFT_ENABLE_NATIVE=1` is set and the `PhysXNative` product is
available, the same descriptor can be passed to `NativePhysicsWorld`.
