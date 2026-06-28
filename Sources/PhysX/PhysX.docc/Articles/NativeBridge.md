# Native PhysX Bridge

Enable `PhysXNative` only after building NVIDIA Omniverse PhysX.

## Build Inputs

The native bridge is intentionally opt-in because Swift Package Manager cannot
build the upstream PhysX CMake project as a normal package target. Set these
environment variables before invoking SwiftPM:

```bash
export PHYSX_SDK_ROOT=/path/to/PhysX
export PHYSX_LIBRARY_PATH=$PHYSX_SDK_ROOT/physx/bin/linux.x86_64/release
export PHYSX_SWIFT_ENABLE_NATIVE=1
```

The package manifest then adds two targets:

- `CPhysX`, a C++14 shim around `PxPhysicsAPI.h`
- `PhysXNative`, a Swift implementation of `PhysicsWorld`

Use `PHYSX_SWIFT_LIBRARIES`, `PHYSX_SWIFT_CXX_FLAGS`, and
`PHYSX_SWIFT_LINKER_FLAGS` when your PhysX build uses non-default library names
or link flags.
