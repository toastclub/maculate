#!/bin/bash

set -e

deps_names=(
    #"libiconv"
    #"gettext"
    #"libxml2"
    #"gmp"
    #"mpfr"
    #"icu"
)
deps_urls=(
    #"https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz"
    #"https://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.1.tar.gz"
    #"https://download.gnome.org/sources/libxml2/2.13/libxml2-2.13.5.tar.xz"
    #"https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz"
    #"https://www.mpfr.org/mpfr-4.2.1/mpfr-4.2.1.tar.gz"
    #"https://github.com/unicode-org/icu/releases/download/release-72-1/icu4c-72_1-src.tgz"
)

# Define install and build directories
INSTALL_DIR="$(pwd)/install"
BUILD_DIR="$(pwd)/build"
SRC_DIR="$(pwd)/src"

# Create necessary directories
mkdir -p "${INSTALL_DIR}/ios" "${BUILD_DIR}" "${SRC_DIR}"

# Clone ios-cmake if not already present
if [ ! -d "ios-cmake" ]; then
    git clone https://github.com/leetal/ios-cmake.git
fi

# Function to download and extract tarballs
download_and_extract() {
    local url=$1
    local dest_dir=$2
    local filename=$(basename "$url")

    if [[ ! -f "${SRC_DIR}/${filename}" ]]; then
        curl -L -o "${SRC_DIR}/${filename}" "$url"
    fi

    tar -xf "${SRC_DIR}/${filename}" -C "${dest_dir}"
}

# Function to configure and build a dependency using CMake
configure_and_build_cmake() {
    local name=$1
    local url=$2
    local prefix="${INSTALL_DIR}/ios/${name}"

    mkdir -p "${BUILD_DIR}/${name}"
    download_and_extract "$url" "${BUILD_DIR}/${name}"

    # Enter the extracted directory
    cd "${BUILD_DIR}/${name}"/*/
    if [[ "$name" == "icu" ]]; then
        cp -r source/* .
    fi

    # Configure and build
    if [[ -f "CMakeLists.txt" ]]; then
        mkdir -p build && cd build

        # Special handling for libxml2
        if [[ "$name" == "libxml2" ]]; then
            echo "Compiling libxml2..."
            sed -i '' 's/check_function_exists(getentropy HAVE_GETENTROPY)/set(HAVE_DECL_GETENTROPY OFF)/' ../CMakeLists.txt
            cmake .. \
                -DCMAKE_TOOLCHAIN_FILE=../../../ios-cmake/ios.toolchain.cmake \
                -DPLATFORM=OS64 \
                -GXcode \
                -DCMAKE_INSTALL_PREFIX="${prefix}"\
                -DLIBXML2_WITH_PROGRAMS=OFF \
                -DLIBXML2_WITH_MODULES=OFF \
                -DLIBXML2_WITH_ICONV=OFF \
                -DLIBXML2_WITH_PYTHON=OFF \
        else
            cmake .. \
                -DCMAKE_TOOLCHAIN_FILE=../../../ios-cmake/ios.toolchain.cmake \
                -DPLATFORM=OS64 \
                -GXcode \
                -DCMAKE_INSTALL_PREFIX="${prefix}"
        fi

        cmake --build . --config Release
        cmake --install . --config Release
    else
        if [[ "$name" == "gmp" ]]; then
            CPPFLAGS="-fembed-bitcode -arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/" ./configure --disable-assembly --host=arm-apple-darwin --prefix="${prefix}" --enable-static --disable-shared --with-mp-limb-size=64
        elif [[ "$name" == "mpfr" ]]; then
            ./configure \
                --host=arm-apple-darwin \
                --prefix="${prefix}" \
                --enable-static \
                --disable-shared \
                --with-gmp="${INSTALL_DIR}/ios/gmp" \
                LDFLAGS="-arch arm64" \
                CFLAGS="-arch arm64" \
                CPPFLAGS="-fembed-bitcode -arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/"
        else
            LDFLAGS="-arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk" CFLAGS="-arch arm64" CPPFLAGS="-fembed-bitcode -arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/" ./configure --host=arm-apple-darwin --prefix="${prefix}" --enable-static --disable-shared
        fi
        make
        make install
    fi

    # Return to the script's root directory
    cd -
}

# Loop through each dependency and build
for i in "${!deps_names[@]}"; do
    echo "Building ${deps_names[i]}..."
    configure_and_build_cmake "${deps_names[i]}" "${deps_urls[i]}"
done

# Clone and build libqalculate
VERSION="5.3.0"
REPO="https://github.com/qalculate/libqalculate"

#git clone --branch v${VERSION} ${REPO}.git ${SRC_DIR}/libqalculate
cd ${SRC_DIR}/libqalculate

mkdir -p ${BUILD_DIR}/ios/libqalculate

echo "Compiling libqalculate..."

# replace instances of libtoolize with glibtoolize, only if its not already done
if ! grep -q "glibtoolize" autogen.sh; then
    sed -i '' 's/libtoolize/glibtoolize/' autogen.sh
fi
INCLUDE_DIRS=(
    "${INSTALL_DIR}/ios/gmp/include"
    "${INSTALL_DIR}/ios/mpfr/include"
    "${INSTALL_DIR}/ios/libxml2/include"
    #"${INSTALL_DIR}/ios/gettext/include"
    #"${INSTALL_DIR}/ios/libiconv/include"
    "${INSTALL_DIR}/ios/icu/include"
)
LIB_DIRS=(
    "${INSTALL_DIR}/ios/gmp/lib"
    "${INSTALL_DIR}/ios/mpfr/lib"
    "${INSTALL_DIR}/ios/libxml2/lib"
    #"${INSTALL_DIR}/ios/gettext/lib"
    #"${INSTALL_DIR}/ios/libiconv/lib"
    "${INSTALL_DIR}/ios/icu/lib"
)

export CFLAGS="-fembed-bitcode -arch arm64 $(printf -- '-I%s ' "${INCLUDE_DIRS[@]}")"
export LDFLAGS="-arch arm64 $(printf -- '-L%s ' "${LIB_DIRS[@]}") -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/"
export CPPFLAGS="-fembed-bitcode -arch arm64 $(printf -- '-I%s ' "${INCLUDE_DIRS[@]}") -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/"
export NOCONFIGURE=1
./autogen.sh
./configure \
    --host=arm-apple-darwin \
    --prefix="${INSTALL_DIR}/ios/libqalculate"\
    --enable-static \
    --disable-shared \
    --with-icu=no \
    --with-readline=no \
    --without-libcurl \
    --enable-unittests=no \



make -j$(sysctl -n hw.ncpu)


echo "Build process completed successfully."
