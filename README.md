# PhysX Swift

Swift 6.3 SDK surface for [NVIDIA Omniverse PhysX](https://github.com/NVIDIA-Omniverse/PhysX).

This package has two layers:

- `PhysX`: a portable Swift API with value types, validation, descriptors, errors, and a deterministic in-memory reference backend for tests and tooling.
- `PhysXNative`: an opt-in native bridge to NVIDIA PhysX through a small C++ shim. It is only added to the package graph when `PHYSX_SWIFT_ENABLE_NATIVE=1`.

The current inspected PhysX release is `ovphysx-0.4.13`. That upstream tree publishes Linux and Windows build presets/readmes. The Swift API itself builds on macOS, Linux, and Windows; the native bridge is intended for PhysX builds on Linux x86_64, Linux aarch64, and Windows x86_64.

## Use the Swift API

```swift
import PhysX

let world = InMemoryPhysicsWorld(scene: .init())

let body = try world.addRigidBody(.init(
    kind: .dynamic,
    transform: .init(position: [0, 10, 0]),
    geometry: .sphere(radius: 0.5),
    material: .default,
    density: 1
))

try world.step(1.0 / 60.0)
let transform = try world.transform(of: body)
```

## Enable the native bridge

Build NVIDIA PhysX first, then point this package at the checkout and library folder:

```bash
export PHYSX_SDK_ROOT=/path/to/PhysX
export PHYSX_LIBRARY_PATH=$PHYSX_SDK_ROOT/physx/bin/linux.x86_64/release
export PHYSX_SWIFT_ENABLE_NATIVE=1
swift build --product PhysXNative
```

If your build produces static archives or platform-specific library names, override the link list:

```bash
export PHYSX_SWIFT_LIBRARIES="PhysX_static PhysXCommon_static PhysXFoundation_static PhysXExtensions_static PhysXPvdSDK_static"
```

Additional C++ and linker flags can be supplied with `PHYSX_SWIFT_CXX_FLAGS` and `PHYSX_SWIFT_LINKER_FLAGS`.

## Test and documentation

```bash
swift test
swift package generate-documentation --target PhysX --warnings-as-errors
```

The core test suite does not require a local PhysX build. Native smoke tests should be added to platform CI jobs that provision NVIDIA PhysX binaries.
