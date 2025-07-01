// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let release = "min.v7.1.1.1"

let frameworks = ["libavcodec": "3084933bb97e0f7875eccc0844340b33b1127475aefd1d8f112c0825a8d8646b", "libavdevice": "2e555b49e3dd9eef80f4af823e19fda85443e913bccdf8bcdba0cc17f81ad24e", "libavfilter": "e27fcfe73d86ccf59e4c6da9aa4f5366ffb469c4072aaf76fd65832d32b93b0b", "libavformat": "1b93279b393146190a0454e87d022747ec416f63c8c9c2540e2e00044a79cb1e", "libavutil": "31d960263bfe74429a7894adc4146d7c09ec23e2c53e4f2b8a71268c52320df2", "libswresample": "a2e6ae61b8bea66155e1c005aa61f3fa8ed1ac7a013093b528f7202800869003", "libswscale": "5208ff3abd692ec1a80a1621d150d999c8c174899e01bec98fdc093829eaeae4"]

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
