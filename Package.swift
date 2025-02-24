// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let release = "min.v7.1.1"

let frameworks = ["ffmpegkit": "159778d1c28ec403faeb6a14b84eeced6150fc1fae6ac92f6d61655e406d3437", "libavcodec": "3ea2676cda196af7d608094856107b8d3fac100eee20c6c6cd6c2f9ae7d245fc", "libavdevice": "780b258c01a51eb85bf7d713d1b0af8d2878f1faf2e5df48fcc3ca0302791da6", "libavfilter": "24b5a392b6591685ab01739dd9a0251815bdec1623f3e47e2061e76ebf746224", "libavformat": "5995cf7a639f71595a75f9a8f6b52a1ac4daa4557aa76f3f26cbc763f600743b", "libavutil": "db0ec243ce70e80ae4e43499ab4ebbc5a3651e5522acc856f8bae48f058378c4", "libswresample": "60c94c4ff479049daaa774e159076459bd93096c0d7ab4c65ca59060400b12af", "libswscale": "ff2b05b667e732fe93968f0371ac722abbb4006ec00cc1068d77a1a007fb52c2"]

func xcframework(_ package: Dictionary<String, String>.Element) -> Target {
    let url = "https://github.com/tylerjonesio/ffmpeg-libav-spm/releases/download/\(release)/\(package.key).xcframework.zip"
    return .binaryTarget(name: package.key, url: url, checksum: package.value)
}

let linkerSettings: [LinkerSetting] = [
    .linkedFramework("AudioToolbox", .when(platforms: [.macOS, .iOS, .macCatalyst, .tvOS])),
    .linkedFramework("AVFoundation", .when(platforms: [.macOS, .iOS, .macCatalyst])),
    .linkedFramework("CoreMedia", .when(platforms: [.macOS])),
    .linkedFramework("OpenGL", .when(platforms: [.macOS])),
    .linkedFramework("VideoToolbox", .when(platforms: [.macOS, .iOS, .macCatalyst, .tvOS])),
    .linkedLibrary("z"),
    .linkedLibrary("lzma"),
    .linkedLibrary("bz2"),
    .linkedLibrary("iconv")
]

let libAVFrameworks = frameworks.filter({ $0.key != "ffmpegkit" })

let package = Package(
    name: "ffmpeg-libav-spm",
    platforms: [.iOS(.v12), .macOS(.v10_15), .tvOS(.v12), .watchOS(.v7)],
    products: [
        .library(
            name: "FFmpeg",
            type: .dynamic,
            targets: ["FFmpeg"] + libAVFrameworks.map { $0.key }),
    ] + libAVFrameworks.map { .library(name: $0.key, targets: [$0.key]) },
    dependencies: [],
    targets: [
        .target(
            name: "FFmpeg",
            dependencies: libAVFrameworks.map { .byName(name: $0.key) },
            linkerSettings: linkerSettings),
    ] + frameworks.map { xcframework($0) }
)
