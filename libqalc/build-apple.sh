#!/bin/bash
# Build arm64 Apple dependencies without Nix or a signing certificate.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
CACHE=${APPLE_BUILD_DIR:-"$ROOT/.build/apple"}
FRAMEWORKS="$ROOT/Qalculate/frameworks"
SOURCES="$CACHE/src"
export PATH="$CACHE/tools/bin:/opt/homebrew/opt/gettext/bin:/usr/local/opt/gettext/bin:$PATH"
JOBS=${APPLE_BUILD_JOBS:-8}
mkdir -p "$SOURCES" "$FRAMEWORKS" "$CACHE/packaging"

case "${1:-macosx}" in
    macosx|iphoneos|iphonesimulator) SDKS="${1:-macosx}" ;;
    all) SDKS="macosx iphoneos iphonesimulator" ;;
    *) echo "Usage: $0 [macosx|iphoneos|iphonesimulator|all]" >&2; exit 2 ;;
esac
command -v msgfmt >/dev/null || { echo 'Install gettext first: brew install gettext' >&2; exit 1; }
xcrun --sdk macosx --show-sdk-path >/dev/null

fetch() {
    local archive=$1 checksum=$2 url=$3 directory=$4
    if [ ! -f "$SOURCES/$archive" ]; then
        curl --fail --location --retry 2 "$url" -o "$SOURCES/$archive"
    fi
    echo "$checksum  $SOURCES/$archive" | shasum -a 256 -c - >/dev/null
    if [ ! -d "$SOURCES/$directory" ]; then
        tar -xf "$SOURCES/$archive" -C "$SOURCES"
    fi
}

fetch gmp-6.3.0.tar.xz a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898 \
    https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz gmp-6.3.0
fetch mpfr-4.2.2.tar.xz b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01 \
    https://www.mpfr.org/mpfr-4.2.2/mpfr-4.2.2.tar.xz mpfr-4.2.2
fetch libqalculate-5.3.0.tar.gz 61dd60b1d43ad3d2944cff9b2f45c9bc646c5a849c621133ef07231e8289e35b \
    https://github.com/Qalculate/libqalculate/releases/download/v5.3.0/libqalculate-5.3.0.tar.gz libqalculate-5.3.0

if [ ! -x "$CACHE/tools/bin/intltool-update" ]; then
    fetch intltool-0.51.0.tar.gz 67c74d94196b153b774ab9f89b2fa6c6ba79352407037c8c14d5aeb334e959cd \
        https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz intltool-0.51.0
    mkdir -p "$CACHE/intltool"
    (cd "$CACHE/intltool"
     "$SOURCES/intltool-0.51.0/configure" --prefix="$CACHE/tools"
     make -j"$JOBS"
     make install) >"$CACHE/intltool.log" 2>&1
fi

build_sdk() (
    local sdk=$1 target prefix sdk_path libraries library archive
    case "$sdk" in
        macosx) target=arm64-apple-macos14.3 ;;
        iphoneos) target=arm64-apple-ios17.0 ;;
        iphonesimulator) target=arm64-apple-ios17.0-simulator ;;
    esac
    sdk_path=$(xcrun --sdk "$sdk" --show-sdk-path)
    prefix="$CACHE/$sdk/install"
    mkdir -p "$prefix"
    export CC="$(xcrun --sdk "$sdk" -f clang) -target $target -isysroot $sdk_path"
    export CXX="$(xcrun --sdk "$sdk" -f clang++) -target $target -isysroot $sdk_path"
    export CFLAGS="-O2 -fPIC" CXXFLAGS="-O2 -fPIC -std=c++17"
    export CPPFLAGS="-I$prefix/include" LDFLAGS="-L$prefix/lib"
    export AR="$(xcrun -f ar)" RANLIB="$(xcrun -f ranlib)"
    export PKG_CONFIG=/usr/bin/false
    export LIBXML_CFLAGS="-I$sdk_path/usr/include/libxml2" LIBXML_LIBS=-lxml2
    libraries="gmp mpfr"
    if [ "$sdk" = macosx ]; then
        fetch icu4c-76_1-src.tgz dfacb46bfe4747410472ce3e1144bf28a102feeaa4e3875bac9b4c6cf30f4f3e \
            https://github.com/unicode-org/icu/releases/download/release-76-1/icu4c-76_1-src.tgz icu
        libraries="$libraries icu"
    fi
    for library in $libraries libqalculate; do
        archive=$library
        [ "$library" != icu ] || archive=icuuc
        [ "$library" != libqalculate ] || archive=qalculate
        [ ! -f "$prefix/lib/lib$archive.a" ] || continue
        mkdir -p "$CACHE/$sdk/$library"
        cd "$CACHE/$sdk/$library"
        case "$library" in
            gmp) "$SOURCES/gmp-6.3.0/configure" --host=aarch64-apple-darwin --prefix="$prefix" --disable-shared --enable-static --disable-assembly ;;
            mpfr) "$SOURCES/mpfr-4.2.2/configure" --host=aarch64-apple-darwin --prefix="$prefix" --disable-shared --enable-static --with-gmp="$prefix" ;;
            icu) "$SOURCES/icu/source/configure" --prefix="$prefix" --disable-shared --enable-static --disable-tests --disable-samples --disable-extras --disable-icuio --with-data-packaging=static ;;
            libqalculate)
                local icu_option=--without-icu
                if [ "$sdk" = macosx ]; then
                    icu_option=--with-icu
                    export ICU_CFLAGS="-I$prefix/include" ICU_LIBS="-L$prefix/lib -licui18n -licuuc -licudata"
                fi
                "$SOURCES/libqalculate-5.3.0/configure" --host=aarch64-apple-darwin --prefix="$prefix" \
                    --disable-shared --enable-static --disable-nls --without-libcurl "$icu_option" \
                    --without-readline --without-gnuplot-call --disable-textport --enable-compiled-definitions --disable-unittests
                ;;
        esac
        make -j"$JOBS"
        make install
    done
    mkdir -p "$ROOT/result/include"
    cp -R "$prefix/include/." "$ROOT/result/include/"
)

for sdk in $SDKS; do
    echo "Building $sdk dependencies (log: $CACHE/build-$sdk.log)"
    # Keep build_sdk outside a conditional so set -e applies inside it.
    trap 'tail -50 "$CACHE/build-$sdk.log" >&2' ERR
    build_sdk "$sdk" >"$CACHE/build-$sdk.log" 2>&1
    trap - ERR
done

# Each library exports only its own headers. Preserve existing platform slices
# when rebuilding just one platform so an iOS build cannot remove macOS support.
package() {
    local name=$1 library=$2 header=$3 sdk slice prefix source header_dir
    shift 3
    local args=()
    for sdk in "$@"; do
        case "$sdk" in
            macosx) slice=macos-arm64 ;;
            iphoneos) slice=ios-arm64 ;;
            iphonesimulator) slice=ios-arm64-simulator ;;
        esac
        prefix="$CACHE/$sdk/install"
        source="$prefix/lib/lib$library.a"
        header_dir="$CACHE/packaging/headers/$sdk/$name"
        if [ -f "$source" ]; then
            args+=(-library "$source")
            if [ "$header" != none ]; then
                rm -rf "$header_dir"
                mkdir -p "$header_dir"
                case "$header" in
                    qalculate) cp -R "$prefix/include/libqalculate" "$header_dir/" ;;
                    gmp) cp "$prefix/include/gmp.h" "$header_dir/" ;;
                    mpfr) cp "$prefix/include/mpfr.h" "$prefix/include/mpf2mpfr.h" "$header_dir/" ;;
                esac
                args+=(-headers "$header_dir")
            fi
        elif [ -f "$FRAMEWORKS/$name.xcframework/$slice/lib$library.a" ]; then
            args+=(-library "$FRAMEWORKS/$name.xcframework/$slice/lib$library.a")
            [ "$header" = none ] || args+=(-headers "$FRAMEWORKS/$name.xcframework/$slice/Headers")
        fi
    done
    [ "${#args[@]}" -gt 0 ] || return 0
    local output="$CACHE/packaging/$name.xcframework"
    rm -rf "$output"
    if ! xcodebuild -create-xcframework "${args[@]}" -output "$output" >"$CACHE/package-$name.log" 2>&1; then
        cat "$CACHE/package-$name.log" >&2
        exit 1
    fi
    mkdir -p "$FRAMEWORKS/$name.xcframework"
    rsync -a --delete "$output/" "$FRAMEWORKS/$name.xcframework/"
    echo "Packaged $name"
}
package LibQalculate qalculate qalculate macosx iphoneos iphonesimulator
package GMP gmp gmp macosx
package MPFR mpfr mpfr macosx
package GMPiOS gmp gmp iphoneos iphonesimulator
package MPFRIOS mpfr mpfr iphoneos iphonesimulator
package ICUicuuc icuuc none macosx
package ICUicudata icudata none macosx
package ICUicui18n icui18n none macosx
echo 'Dependencies are ready. Open maculate.xcodeproj and select the appropriate destination.'
