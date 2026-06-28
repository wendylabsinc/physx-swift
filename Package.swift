// swift-tools-version: 6.3

import Foundation
import PackageDescription

let environment = ProcessInfo.processInfo.environment

func enabled(_ name: String) -> Bool {
    switch environment[name]?.lowercased() {
    case "1", "true", "yes", "on":
        return true
    default:
        return false
    }
}

func splitList(_ value: String?) -> [String] {
    value?
        .split { $0 == "," || $0 == " " || $0 == ";" }
        .map(String.init) ?? []
}

let nativeBridgeEnabled = enabled("PHYSX_SWIFT_ENABLE_NATIVE")
let physxRoot = environment["PHYSX_SDK_ROOT"].flatMap { $0.isEmpty ? nil : $0 }
let physxLibraryPath = environment["PHYSX_LIBRARY_PATH"].flatMap { $0.isEmpty ? nil : $0 }

var products: [Product] = [
    .library(name: "PhysX", targets: ["PhysX"])
]

var targets: [Target] = [
    .target(
        name: "PhysX",
        swiftSettings: [
            .swiftLanguageMode(.v6)
        ]
    ),
    .testTarget(
        name: "PhysXTests",
        dependencies: ["PhysX"],
        swiftSettings: [
            .swiftLanguageMode(.v6)
        ]
    )
]

if nativeBridgeEnabled {
    guard let physxRoot else {
        fatalError("PHYSX_SWIFT_ENABLE_NATIVE requires PHYSX_SDK_ROOT to point at a NVIDIA-Omniverse/PhysX checkout.")
    }

    guard let physxLibraryPath else {
        fatalError("PHYSX_SWIFT_ENABLE_NATIVE requires PHYSX_LIBRARY_PATH to point at the built PhysX libraries, for example $PHYSX_SDK_ROOT/physx/bin/linux.x86_64/release.")
    }

    let includeRoot = "\(physxRoot)/physx/include"
    let cxxFlags = [
        "-std=c++14",
        "-I\(includeRoot)"
    ] + splitList(environment["PHYSX_SWIFT_CXX_FLAGS"])

    let defaultLibraries = [
        "PhysX",
        "PhysXCommon",
        "PhysXFoundation",
        "PhysXExtensions",
        "PhysXPvdSDK"
    ]
    let libraries = splitList(environment["PHYSX_SWIFT_LIBRARIES"]).isEmpty
        ? defaultLibraries
        : splitList(environment["PHYSX_SWIFT_LIBRARIES"])

    let linkerFlags = ["-L\(physxLibraryPath)"]
        + libraries.map { "-l\($0)" }
        + splitList(environment["PHYSX_SWIFT_LINKER_FLAGS"])

    products.append(.library(name: "PhysXNative", targets: ["PhysXNative"]))
    targets.append(contentsOf: [
        .target(
            name: "CPhysX",
            cxxSettings: [
                .unsafeFlags(cxxFlags)
            ],
            linkerSettings: [
                .unsafeFlags(linkerFlags)
            ]
        ),
        .target(
            name: "PhysXNative",
            dependencies: ["PhysX", "CPhysX"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ])
}

let package = Package(
    name: "physx-swift",
    platforms: [
        .macOS(.v14)
    ],
    products: products,
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.5.0")
    ],
    targets: targets,
    cxxLanguageStandard: .cxx14
)
