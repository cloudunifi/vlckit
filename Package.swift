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
            url: "https://github.com/cloudunifi/vlckit/releases/download/vlckit-20261031-1818-fd814768b-44a4d52/VLCKit-4.0-20261031-1818-fd814768b-44a4d52.zip",
            checksum: "06b9c22a8aaeaca73e287bd266154f4772431bf946cc7e5f08fa4f25104adbe4"
        )
    ]
)
