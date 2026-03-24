// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let release = "min.v7.1.3.0"
let androidBundleName = "ffmpegandroid"
let androidBundleChecksum = "120700b0253ca0acd036b82c3e4dbf816edb4cf5623e244244e999e92b61002a"

let frameworks = ["libavcodec": "03426fcda41ec61b925afbb6cf0c5e8796c569443ef53f32bbb74191f0b4386c", "libavdevice": "2d5f4489e6769e2859f3a04d545cb1962251da41291bb40b6851ec3b52bf03c9", "libavfilter": "c4fa55e438cc1638357f48c07716e2712b0f78b7e83f7824ff3b07fc4d4ed9c7", "libavformat": "e5e4e7ef94a275529c0852f2865e0dc6f3965c1ee991e281ecaa525529ab8e2c", "libavutil": "b87310b863224f7bf7095c1aae8835d173335bd945714776d9e9d6e2fa6eded7", "libswresample": "46bbe79946676a0293ae8f60ef27980a2bee93abf1b8fa3b43466ddc985e5df4", "libswscale": "1497cee3d8fd96fef8dc1480b20aacaa5717c875fb9c80ec698a34552372e5d1"]

func xcframework(_ package: Dictionary<String, String>.Element) -> Target {
    let url = "https://github.com/tylerjonesio/ffmpeg-libav-spm/releases/download/\(release)/\(package.key).xcframework.zip"
    return .binaryTarget(name: package.key, url: url, checksum: package.value)
}

func androidArtifactBundle() -> Target {
    let url = "https://github.com/tylerjonesio/ffmpeg-libav-spm/releases/download/\(release)/\(androidBundleName).artifactbundle.zip"
    return .binaryTarget(name: androidBundleName, url: url, checksum: androidBundleChecksum)
}

let linkerSettings: [LinkerSetting] = [
    .linkedFramework("AudioToolbox", .when(platforms: [.macOS, .iOS, .macCatalyst, .tvOS])),
    .linkedFramework("AVFoundation", .when(platforms: [.macOS, .iOS, .macCatalyst])),
    .linkedFramework("CoreMedia", .when(platforms: [.macOS])),
    .linkedFramework("OpenGL", .when(platforms: [.macOS])),
    .linkedFramework("VideoToolbox", .when(platforms: [.macOS, .iOS, .macCatalyst, .tvOS])),
    .linkedLibrary("lzma", .when(platforms: [.macOS, .iOS, .macCatalyst, .tvOS])),
    .linkedLibrary("bz2", .when(platforms: [.macOS, .iOS, .macCatalyst, .tvOS])),
    .linkedLibrary("iconv", .when(platforms: [.macOS, .iOS, .macCatalyst, .tvOS])),
    .linkedLibrary("android", .when(platforms: [.android])),
    .linkedLibrary("mediandk", .when(platforms: [.android])),
    .linkedLibrary("camera2ndk", .when(platforms: [.android])),
    .linkedLibrary("z"),
]

let package = Package(
    name: "ffmpeg-libav-spm",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15)],
    products: [
        .library(
            name: "FFmpeg",
            targets: ["FFmpeg"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FFmpeg",
            dependencies:
                frameworks.map { .byName(name: $0.key, condition: .when(platforms: [.iOS, .tvOS, .macOS, .macCatalyst, .watchOS])) } +
                [.byName(name: "ffmpegandroid", condition: .when(platforms: [.android])) ],
            linkerSettings: linkerSettings),
        androidArtifactBundle()
    ]
    + frameworks.map { xcframework($0) }
)
