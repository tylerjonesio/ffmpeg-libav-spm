#!/bin/sh
set -e

FFMPEG_KIT_TAG="min.v7.1.3.0"
FFMPEG_KIT_CHECKOUT="origin/develop"
#FFMPEG_KIT_CHECKOUT="origin/tags/$FFMPEG_KIT_TAG"

FFMPEG_KIT_REPO="https://github.com/tylerjonesio/ffmpeg-kit"
WORK_DIR=".tmp/ffmpeg-kit"

if [[ ! -d $WORK_DIR ]]; then
  echo "Cloning ffmpeg-kit repository..."
  mkdir .tmp/ || true
  cd .tmp/
  git clone $FFMPEG_KIT_REPO
  cd ../
fi

echo "Checking out $FFMPEG_KIT_CHECKOUT..."
cd $WORK_DIR
git fetch
git fetch --tags
git checkout $FFMPEG_KIT_CHECKOUT

echo "Install build dependencies..."
brew install autoconf automake libtool pkg-config curl git doxygen nasm bison wget gettext gh

echo "Building for iOS..."
./ios.sh --target=15.0 --mac-catalyst-target=15.0 --enable-ios-audiotoolbox --enable-ios-avfoundation --enable-ios-videotoolbox --enable-ios-zlib --enable-ios-bzip2 --no-bitcode --enable-gmp --enable-gnutls -x
echo "Building for tvOS..."
./tvos.sh --target=15.0 --enable-tvos-audiotoolbox --enable-tvos-videotoolbox --enable-tvos-zlib --enable-tvos-bzip2 --no-bitcode --enable-gmp --enable-gnutls -x
echo "Building for macOS..."
./macos.sh --target=12.0 --enable-macos-audiotoolbox --enable-macos-avfoundation --enable-macos-bzip2 --enable-macos-videotoolbox --enable-macos-zlib --enable-macos-coreimage --enable-macos-opencl --enable-macos-opengl --enable-gmp --enable-gnutls -x
#echo "Building for watchOS..."
#./watchos.sh --enable-watchos-zlib --enable-watchos-bzip2 --no-bitcode --enable-gmp --enable-gnutls -x

echo "Bundling final XCFramework"
./apple.sh --disable-watchos --disable-watchsimulator

cd ../../

echo "Updating package file..."
PACKAGE_STRING=""
sed -i '' -e "s/let release =.*/let release = \"$FFMPEG_KIT_TAG\"/" Package.swift

XCFRAMEWORK_DIR="$WORK_DIR/prebuilt/bundle-apple-xcframework"

rm -rf $XCFRAMEWORK_DIR/*.zip

for f in $(ls "$XCFRAMEWORK_DIR")
do
    echo "Adding $f to package list..."
    PACAKGE="$XCFRAMEWORK_DIR/$f"
    ditto -c -k --sequesterRsrc --keepParent $PACAKGE "$PACAKGE.zip"
    PACKAGE_NAME=$(basename "$f" .xcframework)
    PACKAGE_SUM=$(sha256sum "$PACAKGE.zip" | awk '{ print $1 }')
    PACKAGE_STRING="$PACKAGE_STRING\"$PACKAGE_NAME\": \"$PACKAGE_SUM\", "
done

PACKAGE_STRING=$(basename "$PACKAGE_STRING" ", ")
sed -i '' -e "s/let frameworks =.*/let frameworks = [$PACKAGE_STRING]/" Package.swift


# ANDROID GOES HERE
if [[ -z "${ANDROID_SDK_ROOT}" && -d "$HOME/Library/Android/sdk" ]]; then
  export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
fi

if [[ -z "${ANDROID_NDK_ROOT}" && -d "$HOME/Library/Android/ndk" ]]; then
  export ANDROID_NDK_ROOT="$HOME/Library/Android/ndk"
fi

# Fallback for sdkmanager-style NDK installs under ~/Library/Android/sdk/ndk/<version>.
if [[ -z "${ANDROID_NDK_ROOT}" && -d "$HOME/Library/Android/sdk/ndk" ]]; then
  NDK_VERSION_DIR=$(find "$HOME/Library/Android/sdk/ndk" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)
  if [[ -n "${NDK_VERSION_DIR}" ]]; then
    export ANDROID_NDK_ROOT="$NDK_VERSION_DIR"
  fi
fi

echo "Building for Android..."
./android.sh --disable-arm-v7a-neon --enable-android-media-codec --enable-android-zlib --enable-gmp --enable-gnutls

cd ../../

echo "Creating Android artifact bundles..."
ANDROID_PREBUILT_DIR="$WORK_DIR/prebuilt"
ANDROID_BUNDLE_DIR="$WORK_DIR/prebuilt/bundle-android-artifacts"

mkdir -p "$ANDROID_BUNDLE_DIR"
rm -rf "$ANDROID_BUNDLE_DIR"/*.artifactbundle
rm -f "$ANDROID_BUNDLE_DIR"/*.zip

ANDROID_ARCH_DIRS=$(find "$ANDROID_PREBUILT_DIR" -maxdepth 1 -type d -name "android-*")
if [[ -z "$ANDROID_ARCH_DIRS" ]]; then
  echo "No Android prebuilt directories found in $ANDROID_PREBUILT_DIR"
  exit 1
fi

android_triple_for_arch() {
  case "$1" in
    android-arm64-v8a|android-arm64)
      echo "aarch64-unknown-linux-android"
      ;;
    android-arm-v7a|android-armeabi-v7a|android-arm)
      echo "armv7-unknown-linux-android"
      ;;
    android-x86-64|android-x86_64|android-x64)
      echo "x86_64-unknown-linux-android"
      ;;
    android-x86)
      echo "i686-unknown-linux-android"
      ;;
    *)
      echo ""
      ;;
  esac
}

resolve_android_llvm_ar() {
  if [[ -n "${ANDROID_NDK_ROOT}" && -d "${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt" ]]; then
    TOOLCHAIN_AR=$(find "${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt" -type f -name "llvm-ar" | head -n 1)
    if [[ -n "$TOOLCHAIN_AR" ]]; then
      echo "$TOOLCHAIN_AR"
      return
    fi
  fi

  TOOLCHAIN_AR=$(find "$HOME/Library/Android" -type f -path "*/toolchains/llvm/prebuilt/*/bin/llvm-ar" 2>/dev/null | head -n 1)
  if [[ -n "$TOOLCHAIN_AR" ]]; then
    echo "$TOOLCHAIN_AR"
    return
  fi

  if command -v llvm-ar >/dev/null 2>&1; then
    command -v llvm-ar
    return
  fi

  echo ""
}

ANDROID_LLVM_AR=$(resolve_android_llvm_ar)
if [[ -z "$ANDROID_LLVM_AR" ]]; then
  echo "Unable to find llvm-ar. Set ANDROID_NDK_ROOT/ANDROID_NDK_HOME or install llvm-ar."
  exit 1
fi
echo "Using archive tool: $ANDROID_LLVM_AR"

ANDROID_UNIFIED_BUNDLE_NAME="ffmpegandroid"
ANDROID_UNIFIED_BUNDLE_PATH="$ANDROID_BUNDLE_DIR/$ANDROID_UNIFIED_BUNDLE_NAME.artifactbundle"
ANDROID_UNIFIED_INFO_JSON="$ANDROID_UNIFIED_BUNDLE_PATH/info.json"
ANDROID_UNIFIED_TARGET_NAME="$ANDROID_UNIFIED_BUNDLE_NAME"

rm -rf "$ANDROID_UNIFIED_BUNDLE_PATH"
mkdir -p "$ANDROID_UNIFIED_BUNDLE_PATH"

VARIANTS_JSON=""
VARIANT_COUNT=0

for ARCH_DIR in $ANDROID_ARCH_DIRS
do
    ARCH_BASENAME=$(basename "$ARCH_DIR")
    SUPPORTED_TRIPLE=$(android_triple_for_arch "$ARCH_BASENAME")
    if [[ -z "$SUPPORTED_TRIPLE" ]]; then
        echo "Skipping unsupported Android architecture directory: $ARCH_BASENAME"
        continue
    fi

    DEST_DIR="$ANDROID_UNIFIED_BUNDLE_PATH/$ANDROID_UNIFIED_TARGET_NAME/$ARCH_BASENAME"
    mkdir -p "$DEST_DIR"
    DEST_ARCHIVE="$DEST_DIR/lib$ANDROID_UNIFIED_TARGET_NAME.a"

    # Merge ffmpeg and third-party static archives into a single linkable archive.
    MERGE_TMP_DIR=$(mktemp -d)
    MERGE_SCRIPT="$MERGE_TMP_DIR/merge.mri"
    {
        echo "create $DEST_ARCHIVE"
        for LIBAV_NAME in libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale
        do
            LIBAV_ARCHIVE="$ARCH_DIR/ffmpeg/lib/$LIBAV_NAME.a"
            if [[ ! -f "$LIBAV_ARCHIVE" ]]; then
                LIBAV_ARCHIVE="$ARCH_DIR/ffmpeg/lib/${LIBAV_NAME}_neon.a"
            fi
            if [[ ! -f "$LIBAV_ARCHIVE" ]]; then
                echo "Missing required FFmpeg archive for $ARCH_BASENAME: $ARCH_DIR/ffmpeg/lib/$LIBAV_NAME.a"
                exit 1
            fi
            echo "addlib $LIBAV_ARCHIVE"
        done
        for THIRD_PARTY_ARCHIVE in \
            "$ARCH_DIR/libiconv/lib/libiconv.a" \
            "$ARCH_DIR/libiconv/lib/libcharset.a" \
            "$ARCH_DIR/gmp/lib/libgmp.a" \
            "$ARCH_DIR/gnutls/lib/libgnutls.a" \
            "$ARCH_DIR/nettle/lib/libhogweed.a" \
            "$ARCH_DIR/nettle/lib/libnettle.a"
        do
            if [[ ! -f "$THIRD_PARTY_ARCHIVE" ]]; then
                echo "Missing required third-party archive for $ARCH_BASENAME: $THIRD_PARTY_ARCHIVE"
                exit 1
            fi
            echo "addlib $THIRD_PARTY_ARCHIVE"
        done
        echo "save"
        echo "end"
    } > "$MERGE_SCRIPT"
    "$ANDROID_LLVM_AR" -M < "$MERGE_SCRIPT"
    rm -rf "$MERGE_TMP_DIR"

    HEADERS_DIR="$DEST_DIR/Headers"
    FFMPEG_HEADERS_DIR="$ARCH_DIR/ffmpeg/include"
    if [[ ! -d "$FFMPEG_HEADERS_DIR" ]]; then
        echo "Missing ffmpeg headers for $ARCH_BASENAME at $FFMPEG_HEADERS_DIR"
        exit 1
    fi
    mkdir -p "$HEADERS_DIR"
    cp -Rf "$FFMPEG_HEADERS_DIR/." "$HEADERS_DIR/"

    VARIANT_PATH="$ANDROID_UNIFIED_TARGET_NAME/$ARCH_BASENAME/lib$ANDROID_UNIFIED_TARGET_NAME.a"
    HEADER_PATH="$ANDROID_UNIFIED_TARGET_NAME/$ARCH_BASENAME/Headers"
    VARIANT_ENTRY="{\"path\":\"$VARIANT_PATH\",\"supportedTriples\":[\"$SUPPORTED_TRIPLE\"],\"staticLibraryMetadata\":{\"headerPaths\":[\"$HEADER_PATH\"]}}"
    if [[ $VARIANT_COUNT -eq 0 ]]; then
        VARIANTS_JSON="$VARIANT_ENTRY"
    else
        VARIANTS_JSON="$VARIANTS_JSON,$VARIANT_ENTRY"
    fi
    VARIANT_COUNT=$((VARIANT_COUNT + 1))
done

if [[ $VARIANT_COUNT -eq 0 ]]; then
    echo "No Android variants were generated for $ANDROID_UNIFIED_TARGET_NAME."
    exit 1
fi

cat > "$ANDROID_UNIFIED_INFO_JSON" << EOF
{
  "schemaVersion": "1.0",
  "artifacts": {
    "$ANDROID_UNIFIED_TARGET_NAME": {
      "version": "$FFMPEG_KIT_TAG",
      "type": "staticLibrary",
      "variants": [$VARIANTS_JSON]
    }
  }
}
EOF

ditto -c -k --sequesterRsrc --keepParent "$ANDROID_UNIFIED_BUNDLE_PATH" "$ANDROID_UNIFIED_BUNDLE_PATH.zip"
ANDROID_BUNDLE_CHECKSUM=$(shasum -a 256 "$ANDROID_UNIFIED_BUNDLE_PATH.zip" | awk '{ print $1 }')
if [[ -z "$ANDROID_BUNDLE_CHECKSUM" ]]; then
  echo "Failed to calculate checksum for $ANDROID_UNIFIED_BUNDLE_PATH.zip"
  exit 1
fi

sed -i '' -e "s/let androidBundleChecksum =.*/let androidBundleChecksum = \"$ANDROID_BUNDLE_CHECKSUM\"/" Package.swift

echo "Copying License..."
cp -f .tmp/ffmpeg-kit/LICENSE ./

echo "Committing Changes..."
git add -u
git commit -m "Creating release for $FFMPEG_KIT_TAG"

echo "Creating Tag..."
git tag $FFMPEG_KIT_TAG
git push
git push origin --tags

echo "Creating Release..."
gh release create -p -d $FFMPEG_KIT_TAG -t "FFmpeg libav SPM $FFMPEG_KIT_TAG" --generate-notes --verify-tag

echo "Uploading Binaries..."
for f in $(ls "$XCFRAMEWORK_DIR")
do
    if [[ $f == *.zip ]]; then
        gh release upload $FFMPEG_KIT_TAG "$XCFRAMEWORK_DIR/$f"
    fi
done

gh release upload $FFMPEG_KIT_TAG "$ANDROID_UNIFIED_BUNDLE_PATH.zip"

gh release edit $FFMPEG_KIT_TAG --draft=false

echo "All done!"
