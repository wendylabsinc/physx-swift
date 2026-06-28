import Testing
@testable import PhysX

@Suite("Platform support metadata")
struct PlatformSupportTests {
    @Test("Upstream release and native platform metadata are explicit")
    func supportMetadata() {
        #expect(PhysXSwiftSupport.upstreamReleaseTag == "ovphysx-0.4.13")
        #expect(PhysXSwiftSupport.swiftAPIPlatforms.contains("macOS"))
        #expect(PhysXSwiftSupport.swiftAPIPlatforms.contains("Linux"))
        #expect(PhysXSwiftSupport.swiftAPIPlatforms.contains("Windows"))
        #expect(PhysXSwiftSupport.nativePhysXPlatforms == ["Linux x86_64", "Linux aarch64", "Windows x86_64"])
    }
}
