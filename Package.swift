// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VLCKit",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS("7.4"),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "VLCKit", targets: ["VLCKit"])
    ],
    targets: [
        .binaryTarget(
            name: "VLCKit",
            url: "https://github.com/cloudunifi/vlckit/releases/download/vlckit-20261031-1900-fd814768b-88ed3ca/VLCKit-4.0-20261031-1900-fd814768b-88ed3ca.zip",
            checksum: "5fb82125e5f37abe6d71388c2c5f738d58ff17d6ecfe4f779068d90acd6bae18"
        )
    ]
)
