// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let release = "min.v7.1.1.2"
let androidBundleName = "ffmpegandroid"
let androidBundleChecksum = "8a089269253227edfbc729956a6d61f9dfdf2871b20b21b41c17ed8c74e9fcbc"

let frameworks = ["libavcodec": "b07adc881513c2d4f735d2ac4fbcb5bde097b88af42e782802ce6fc61b7668a5", "libavdevice": "232faf15363c148bfbb1128f18bc708c7e27f4416216df6de4ae48868be8b1df", "libavfilter": "739c580ae0290ad83b6680f9a46e335752cb131b6be7a13caf86db3e1746b68e", "libavformat": "afab24f8dd09abb8990e8b0fb17b7783a38489210176d629bb081e1cd92380d3", "libavutil": "e41ee1b6d00fcddc4f137905605f9adb4fc3303a6abe5003ddb63687bbff940d", "libswresample": "aaa72abbc002dd924d92da877bc3eebeb631340f853b3af4f370f324d07fde28", "libswscale": "b6f9e32d77d183fa05ea45e5401334280df76a2a893f24ebcfaeb9fd0b2677d8"]

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
