# ``PhysX``

Build Swift 6.3 applications around NVIDIA Omniverse PhysX concepts.

## Overview

The `PhysX` module defines a backend-neutral Swift API for creating scenes,
rigid bodies, materials, transforms, and geometry. It is designed so application
code can be written and tested without directly importing C++ PhysX headers.

Use `InMemoryPhysicsWorld` for deterministic validation and tooling. Use the
optional `PhysXNative` product when you have built NVIDIA PhysX and want the
same Swift descriptors to create native PhysX actors.

## Topics

### World Interfaces

- ``PhysicsWorld``
- ``InMemoryPhysicsWorld``
- ``RigidBodyID``
- ``RigidBodyState``

### Descriptors

- ``SceneDescriptor``
- ``RigidBodyDescriptor``
- ``BodyKind``
- ``Geometry``
- ``Material``

### Math Types

- ``Vector3``
- ``Quaternion``
- ``Transform``

### Errors and Support

- ``PhysicsError``
- ``PhysXSwiftSupport``
