#include "physx_swift.h"

#include "PxPhysicsAPI.h"
#include "extensions/PxDefaultAllocator.h"
#include "extensions/PxDefaultCpuDispatcher.h"
#include "extensions/PxDefaultErrorCallback.h"
#include "extensions/PxRigidActorExt.h"
#include "extensions/PxRigidBodyExt.h"

#include <cstring>
#include <limits>
#include <unordered_map>
#include <vector>

using namespace physx;

namespace {

constexpr int32_t statusOK = 0;
constexpr int32_t statusInvalidArgument = 1;
constexpr int32_t statusBackendFailure = 2;
constexpr int32_t statusNotFound = 3;

void setStatus(PhysXSwiftStatus *status, int32_t code, const char *message) {
    if (status == nullptr) {
        return;
    }
    status->code = code;
    std::strncpy(status->message, message, sizeof(status->message) - 1);
    status->message[sizeof(status->message) - 1] = '\0';
}

PxVec3 toPx(PhysXSwiftVector3 vector) {
    return PxVec3(vector.x, vector.y, vector.z);
}

PhysXSwiftVector3 fromPx(const PxVec3 &vector) {
    return PhysXSwiftVector3{vector.x, vector.y, vector.z};
}

PxQuat toPx(PhysXSwiftQuaternion quaternion) {
    return PxQuat(quaternion.x, quaternion.y, quaternion.z, quaternion.w).getNormalized();
}

PhysXSwiftQuaternion fromPx(const PxQuat &quaternion) {
    return PhysXSwiftQuaternion{quaternion.x, quaternion.y, quaternion.z, quaternion.w};
}

PxTransform toPx(PhysXSwiftTransform transform) {
    return PxTransform(toPx(transform.position), toPx(transform.rotation));
}

PhysXSwiftTransform fromPx(const PxTransform &transform) {
    return PhysXSwiftTransform{fromPx(transform.p), fromPx(transform.q)};
}

bool isFinite(float value) {
    return value == value
        && value != std::numeric_limits<float>::infinity()
        && value != -std::numeric_limits<float>::infinity();
}

class GeometryBuilder {
public:
    explicit GeometryBuilder(PhysXSwiftGeometry geometry) : geometry_(geometry) {}

    bool create(PxPhysics &physics, PxMaterial &material, PxRigidActor &actor, PhysXSwiftStatus *status) const {
        switch (geometry_.kind) {
        case PhysXSwiftGeometryKindSphere:
            return attach(physics, material, actor, PxSphereGeometry(geometry_.radius), status);
        case PhysXSwiftGeometryKindBox:
            return attach(physics, material, actor, PxBoxGeometry(toPx(geometry_.vector)), status);
        case PhysXSwiftGeometryKindCapsule:
            return attach(physics, material, actor, PxCapsuleGeometry(geometry_.radius, geometry_.halfHeight), status);
        case PhysXSwiftGeometryKindPlane:
            return attach(physics, material, actor, PxPlaneGeometry(), status);
        }
        setStatus(status, statusInvalidArgument, "Unsupported geometry kind.");
        return false;
    }

private:
    template <typename T>
    bool attach(PxPhysics &physics, PxMaterial &material, PxRigidActor &actor, const T &geometry, PhysXSwiftStatus *status) const {
        PxShape *shape = physics.createShape(geometry, material, true);
        if (shape == nullptr) {
            setStatus(status, statusBackendFailure, "PhysX failed to create shape.");
            return false;
        }
        actor.attachShape(*shape);
        shape->release();
        return true;
    }

    PhysXSwiftGeometry geometry_;
};

} // namespace

struct PhysXSwiftWorld {
    PxDefaultAllocator allocator;
    PxDefaultErrorCallback errorCallback;
    PxFoundation *foundation = nullptr;
    PxPhysics *physics = nullptr;
    PxDefaultCpuDispatcher *dispatcher = nullptr;
    PxScene *scene = nullptr;
    uint64_t nextID = 1;
    std::unordered_map<uint64_t, PxRigidActor *> actors;
    std::vector<PxMaterial *> materials;

    bool initialize(PhysXSwiftSceneDescriptor descriptor, PhysXSwiftStatus *status) {
        foundation = PxCreateFoundation(PX_PHYSICS_VERSION, allocator, errorCallback);
        if (foundation == nullptr) {
            setStatus(status, statusBackendFailure, "PhysX failed to create foundation.");
            return false;
        }

        PxTolerancesScale scale;
        physics = PxCreatePhysics(PX_PHYSICS_VERSION, *foundation, scale, false, nullptr);
        if (physics == nullptr) {
            setStatus(status, statusBackendFailure, "PhysX failed to create physics instance.");
            return false;
        }

        if (!PxInitExtensions(*physics, nullptr)) {
            setStatus(status, statusBackendFailure, "PhysX extensions failed to initialize.");
            return false;
        }

        dispatcher = PxDefaultCpuDispatcherCreate(static_cast<PxU32>(descriptor.workerThreadCount));
        if (dispatcher == nullptr) {
            setStatus(status, statusBackendFailure, "PhysX failed to create CPU dispatcher.");
            return false;
        }

        PxSceneDesc sceneDesc(scale);
        sceneDesc.gravity = toPx(descriptor.gravity);
        sceneDesc.cpuDispatcher = dispatcher;
        sceneDesc.filterShader = PxDefaultSimulationFilterShader;
        scene = physics->createScene(sceneDesc);
        if (scene == nullptr) {
            setStatus(status, statusBackendFailure, "PhysX failed to create scene.");
            return false;
        }

        setStatus(status, statusOK, "");
        return true;
    }

    ~PhysXSwiftWorld() {
        for (auto &entry : actors) {
            if (entry.second != nullptr) {
                entry.second->release();
            }
        }
        actors.clear();

        for (PxMaterial *material : materials) {
            if (material != nullptr) {
                material->release();
            }
        }
        materials.clear();

        if (scene != nullptr) {
            scene->release();
        }
        if (dispatcher != nullptr) {
            dispatcher->release();
        }
        if (physics != nullptr) {
            PxCloseExtensions();
            physics->release();
        }
        if (foundation != nullptr) {
            foundation->release();
        }
    }
};

const char *physx_swift_version(void) {
    return "PhysX Swift native bridge for NVIDIA PhysX 5";
}

int32_t physx_swift_world_create(
    PhysXSwiftSceneDescriptor descriptor,
    PhysXSwiftWorld **outWorld,
    PhysXSwiftStatus *status
) {
    if (outWorld == nullptr) {
        setStatus(status, statusInvalidArgument, "outWorld must not be null.");
        return statusInvalidArgument;
    }
    *outWorld = nullptr;

    PhysXSwiftWorld *world = new PhysXSwiftWorld();
    if (!world->initialize(descriptor, status)) {
        delete world;
        return status != nullptr ? status->code : statusBackendFailure;
    }

    *outWorld = world;
    return statusOK;
}

void physx_swift_world_destroy(PhysXSwiftWorld *world) {
    delete world;
}

int32_t physx_swift_world_add_rigid_body(
    PhysXSwiftWorld *world,
    PhysXSwiftRigidBodyDescriptor descriptor,
    uint64_t *outID,
    PhysXSwiftStatus *status
) {
    if (world == nullptr || outID == nullptr) {
        setStatus(status, statusInvalidArgument, "world and outID must not be null.");
        return statusInvalidArgument;
    }

    PxMaterial *material = world->physics->createMaterial(
        descriptor.material.staticFriction,
        descriptor.material.dynamicFriction,
        descriptor.material.restitution
    );
    if (material == nullptr) {
        setStatus(status, statusBackendFailure, "PhysX failed to create material.");
        return statusBackendFailure;
    }
    world->materials.push_back(material);

    PxRigidActor *actor = nullptr;
    PxTransform transform = toPx(descriptor.transform);
    if (descriptor.geometry.kind == PhysXSwiftGeometryKindPlane) {
        PxPlane plane(toPx(descriptor.geometry.vector), descriptor.geometry.distance);
        actor = PxCreatePlane(*world->physics, plane, *material);
    } else if (descriptor.kind == PhysXSwiftBodyKindStatic) {
        actor = world->physics->createRigidStatic(transform);
    } else {
        PxRigidDynamic *dynamicActor = world->physics->createRigidDynamic(transform);
        if (dynamicActor != nullptr) {
            dynamicActor->setLinearVelocity(toPx(descriptor.linearVelocity));
            dynamicActor->setAngularVelocity(toPx(descriptor.angularVelocity));
            if (descriptor.kind == PhysXSwiftBodyKindKinematic) {
                dynamicActor->setRigidBodyFlag(PxRigidBodyFlag::eKINEMATIC, true);
            }
        }
        actor = dynamicActor;
    }

    if (actor == nullptr) {
        setStatus(status, statusBackendFailure, "PhysX failed to create rigid actor.");
        return statusBackendFailure;
    }

    if (descriptor.geometry.kind != PhysXSwiftGeometryKindPlane) {
        GeometryBuilder builder(descriptor.geometry);
        if (!builder.create(*world->physics, *material, *actor, status)) {
            actor->release();
            return status != nullptr ? status->code : statusBackendFailure;
        }
    }

    if (descriptor.kind == PhysXSwiftBodyKindDynamic) {
        PxRigidBodyExt::updateMassAndInertia(*static_cast<PxRigidDynamic *>(actor), descriptor.density);
    }

    uint64_t id = world->nextID++;
    world->actors[id] = actor;
    world->scene->addActor(*actor);
    *outID = id;
    setStatus(status, statusOK, "");
    return statusOK;
}

int32_t physx_swift_world_remove_rigid_body(
    PhysXSwiftWorld *world,
    uint64_t id,
    PhysXSwiftStatus *status
) {
    if (world == nullptr) {
        setStatus(status, statusInvalidArgument, "world must not be null.");
        return statusInvalidArgument;
    }
    auto iterator = world->actors.find(id);
    if (iterator == world->actors.end()) {
        setStatus(status, statusNotFound, "Rigid body was not found.");
        return statusNotFound;
    }
    world->scene->removeActor(*iterator->second);
    iterator->second->release();
    world->actors.erase(iterator);
    setStatus(status, statusOK, "");
    return statusOK;
}

int32_t physx_swift_world_get_transform(
    PhysXSwiftWorld *world,
    uint64_t id,
    PhysXSwiftTransform *outTransform,
    PhysXSwiftStatus *status
) {
    if (world == nullptr || outTransform == nullptr) {
        setStatus(status, statusInvalidArgument, "world and outTransform must not be null.");
        return statusInvalidArgument;
    }
    auto iterator = world->actors.find(id);
    if (iterator == world->actors.end()) {
        setStatus(status, statusNotFound, "Rigid body was not found.");
        return statusNotFound;
    }
    *outTransform = fromPx(iterator->second->getGlobalPose());
    setStatus(status, statusOK, "");
    return statusOK;
}

int32_t physx_swift_world_set_transform(
    PhysXSwiftWorld *world,
    uint64_t id,
    PhysXSwiftTransform transform,
    PhysXSwiftStatus *status
) {
    if (world == nullptr) {
        setStatus(status, statusInvalidArgument, "world must not be null.");
        return statusInvalidArgument;
    }
    auto iterator = world->actors.find(id);
    if (iterator == world->actors.end()) {
        setStatus(status, statusNotFound, "Rigid body was not found.");
        return statusNotFound;
    }
    iterator->second->setGlobalPose(toPx(transform));
    setStatus(status, statusOK, "");
    return statusOK;
}

int32_t physx_swift_world_get_linear_velocity(
    PhysXSwiftWorld *world,
    uint64_t id,
    PhysXSwiftVector3 *outVelocity,
    PhysXSwiftStatus *status
) {
    if (world == nullptr || outVelocity == nullptr) {
        setStatus(status, statusInvalidArgument, "world and outVelocity must not be null.");
        return statusInvalidArgument;
    }
    auto iterator = world->actors.find(id);
    if (iterator == world->actors.end()) {
        setStatus(status, statusNotFound, "Rigid body was not found.");
        return statusNotFound;
    }
    PxRigidDynamic *dynamicActor = iterator->second->is<PxRigidDynamic>();
    if (dynamicActor == nullptr) {
        *outVelocity = PhysXSwiftVector3{0, 0, 0};
    } else {
        *outVelocity = fromPx(dynamicActor->getLinearVelocity());
    }
    setStatus(status, statusOK, "");
    return statusOK;
}

int32_t physx_swift_world_set_linear_velocity(
    PhysXSwiftWorld *world,
    uint64_t id,
    PhysXSwiftVector3 velocity,
    PhysXSwiftStatus *status
) {
    if (world == nullptr) {
        setStatus(status, statusInvalidArgument, "world must not be null.");
        return statusInvalidArgument;
    }
    auto iterator = world->actors.find(id);
    if (iterator == world->actors.end()) {
        setStatus(status, statusNotFound, "Rigid body was not found.");
        return statusNotFound;
    }
    PxRigidDynamic *dynamicActor = iterator->second->is<PxRigidDynamic>();
    if (dynamicActor == nullptr) {
        setStatus(status, statusInvalidArgument, "Static bodies do not have linear velocity.");
        return statusInvalidArgument;
    }
    dynamicActor->setLinearVelocity(toPx(velocity));
    setStatus(status, statusOK, "");
    return statusOK;
}

int32_t physx_swift_world_step(
    PhysXSwiftWorld *world,
    float timeStep,
    PhysXSwiftStatus *status
) {
    if (world == nullptr) {
        setStatus(status, statusInvalidArgument, "world must not be null.");
        return statusInvalidArgument;
    }
    if (!isFinite(timeStep) || timeStep <= 0) {
        setStatus(status, statusInvalidArgument, "Time step must be positive and finite.");
        return statusInvalidArgument;
    }
    world->scene->simulate(timeStep);
    world->scene->fetchResults(true);
    setStatus(status, statusOK, "");
    return statusOK;
}
