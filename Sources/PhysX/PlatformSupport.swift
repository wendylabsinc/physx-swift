/// Build and runtime support metadata for the Swift SDK and native PhysX bridge.
public enum PhysXSwiftSupport {
    /// The upstream NVIDIA Omniverse PhysX release inspected by this SDK.
    public static let upstreamReleaseTag = "ovphysx-0.4.13"

    /// Platforms where the portable Swift API is expected to build.
    public static let swiftAPIPlatforms = [
        "macOS",
        "Linux",
        "Windows"
    ]

    /// Platforms represented by the inspected upstream PhysX build presets.
    public static let nativePhysXPlatforms = [
        "Linux x86_64",
        "Linux aarch64",
        "Windows x86_64"
    ]
}
