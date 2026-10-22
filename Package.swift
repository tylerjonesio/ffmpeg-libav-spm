// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let release = "min.v9.0.2.0"
let androidBundleName = "ffmpegandroid"
let androidBundleChecksum = "ee1d4978ed80300f18ab8e6134b8fbb4d07992f8800f547c4162f504e2a3317c"

let frameworks = ["libavcodec": "2b8179787058dc496920b8c6a8020c0bd6253402a1663eaab39df7cbf32856ac", "libavdevice": "f9259ea17257e0be2af24e03c8db5e051b3d7cdfe733444101d88ddf9960a4fd", "libavfilter": "088e87a904d84a3a204566e6ca14a8af7936cbb484467c34e9493a88381433fa", "libavformat": "24693d7fb33608a1029aafab8eada27499d5fb7d3033809aa774c0281c5e58ed", "libavutil": "46f1f0032aea1d430f651eeaee80c075226761e57618a7486fa9b2446b252e45", "libswresample": "f62f87fb138b864eed561b399b3b217a0fd917862c66a814d744b9aa12d2c21b", "libswscale": "2ac827798ce3603d4dc5b7057dd2d45517ca622697e1df4abf95e2b78ae07946"]

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
