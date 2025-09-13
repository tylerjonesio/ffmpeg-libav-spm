// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let release = "min.v7.1.1.2"

let frameworks = ["libavcodec": "b07adc881513c2d4f735d2ac4fbcb5bde097b88af42e782802ce6fc61b7668a5", "libavdevice": "232faf15363c148bfbb1128f18bc708c7e27f4416216df6de4ae48868be8b1df", "libavfilter": "739c580ae0290ad83b6680f9a46e335752cb131b6be7a13caf86db3e1746b68e", "libavformat": "afab24f8dd09abb8990e8b0fb17b7783a38489210176d629bb081e1cd92380d3", "libavutil": "e41ee1b6d00fcddc4f137905605f9adb4fc3303a6abe5003ddb63687bbff940d", "libswresample": "aaa72abbc002dd924d92da877bc3eebeb631340f853b3af4f370f324d07fde28", "libswscale": "b6f9e32d77d183fa05ea45e5401334280df76a2a893f24ebcfaeb9fd0b2677d8"]

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
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15)],
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
