// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let release = "min.v7.1.2"

let frameworks = ["libavcodec": "310a6c9f507f2862f9ae5deef6ba6985364f611c4afb0cf1edfe620d09cbfbb5", "libavdevice": "d1220f42fe31f63ea48365ecde8028174d999c9dc058f8423729f5c9105fd62c", "libavfilter": "3ec5943231dddb02baa987f6914cf3acd39a23ef2cd831fdc5256071e85892cc", "libavformat": "446a8d6bb62164c5631d235a8c0e3f05c259ef94fa16be636b3c4b1f45e00827", "libavutil": "d6341ec66a4a51060247f3790edcb6bcc02d88634cc73534407996876881fee1", "libswresample": "4b5445ada37ceab64b0ae83ce76ad941609acc5af805400d6d1ff512ec5de71e", "libswscale": "7e797f34f6838464c087b2f9b17b1adfb132adc427eb53f5d247436329c5a753"]

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
