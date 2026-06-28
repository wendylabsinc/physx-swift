#ifndef PHYSX_SWIFT_H
#define PHYSX_SWIFT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct PhysXSwiftWorld PhysXSwiftWorld;

typedef struct PhysXSwiftVector3 {
    float x;
    float y;
    float z;
} PhysXSwiftVector3;

typedef struct PhysXSwiftQuaternion {
    float x;
    float y;
    float z;
    float w;
} PhysXSwiftQuaternion;

typedef struct PhysXSwiftTransform {
    PhysXSwiftVector3 position;
    PhysXSwiftQuaternion rotation;
} PhysXSwiftTransform;

typedef struct PhysXSwiftSceneDescriptor {
    PhysXSwiftVector3 gravity;
    int32_t workerThreadCount;
} PhysXSwiftSceneDescriptor;

typedef enum PhysXSwiftBodyKind {
    PhysXSwiftBodyKindStatic = 0,
    PhysXSwiftBodyKindDynamic = 1,
    PhysXSwiftBodyKindKinematic = 2
} PhysXSwiftBodyKind;

typedef enum PhysXSwiftGeometryKind {
    PhysXSwiftGeometryKindPlane = 0,
    PhysXSwiftGeometryKindSphere = 1,
    PhysXSwiftGeometryKindBox = 2,
    PhysXSwiftGeometryKindCapsule = 3
} PhysXSwiftGeometryKind;

typedef struct PhysXSwiftGeometry {
    PhysXSwiftGeometryKind kind;
    PhysXSwiftVector3 vector;
    float radius;
    float halfHeight;
    float distance;
} PhysXSwiftGeometry;

typedef struct PhysXSwiftMaterial {
    float staticFriction;
    float dynamicFriction;
    float restitution;
} PhysXSwiftMaterial;

typedef struct PhysXSwiftRigidBodyDescriptor {
    PhysXSwiftBodyKind kind;
    PhysXSwiftTransform transform;
    PhysXSwiftGeometry geometry;
    PhysXSwiftMaterial material;
    float density;
    PhysXSwiftVector3 linearVelocity;
    PhysXSwiftVector3 angularVelocity;
} PhysXSwiftRigidBodyDescriptor;

typedef struct PhysXSwiftStatus {
    int32_t code;
    char message[256];
} PhysXSwiftStatus;

const char *physx_swift_version(void);

int32_t physx_swift_world_create(
    PhysXSwiftSceneDescriptor descriptor,
    PhysXSwiftWorld **outWorld,
    PhysXSwiftStatus *status
);

void physx_swift_world_destroy(PhysXSwiftWorld *world);

int32_t physx_swift_world_add_rigid_body(
    PhysXSwiftWorld *world,
    PhysXSwiftRigidBodyDescriptor descriptor,
    uint64_t *outID,
    PhysXSwiftStatus *status
);

int32_t physx_swift_world_remove_rigid_body(
    PhysXSwiftWorld *world,
    uint64_t id,
    PhysXSwiftStatus *status
);

int32_t physx_swift_world_get_transform(
    PhysXSwiftWorld *world,
    uint64_t id,
    PhysXSwiftTransform *outTransform,
    PhysXSwiftStatus *status
);

int32_t physx_swift_world_set_transform(
    PhysXSwiftWorld *world,
    uint64_t id,
    PhysXSwiftTransform transform,
    PhysXSwiftStatus *status
);

int32_t physx_swift_world_get_linear_velocity(
    PhysXSwiftWorld *world,
    uint64_t id,
    PhysXSwiftVector3 *outVelocity,
    PhysXSwiftStatus *status
);

int32_t physx_swift_world_set_linear_velocity(
    PhysXSwiftWorld *world,
    uint64_t id,
    PhysXSwiftVector3 velocity,
    PhysXSwiftStatus *status
);

int32_t physx_swift_world_step(
    PhysXSwiftWorld *world,
    float timeStep,
    PhysXSwiftStatus *status
);

#ifdef __cplusplus
}
#endif

#endif
