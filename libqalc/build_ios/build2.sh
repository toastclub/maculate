#!/bin/bash

set -e

# Define versions and URLs for dependencies using two arrays
deps_names=(
    #"libiconv" "gettext"
    "libxml2" "mpfr" "gmp" "icu")
deps_urls=(
    #"https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz"
    #"https://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.1.tar.gz"
    "https://download.gnome.org/sources/libxml2/2.13/libxml2-2.13.5.tar.xz"
    "https://www.mpfr.org/mpfr-4.2.1/mpfr-4.2.1.tar.gz"
    "https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz"
    "https://github.com/unicode-org/icu/releases/download/release-72-1/icu4c-72_1-src.tgz"
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

    # Configure and build
    if [[ -f "CMakeLists.txt" ]]; then
        mkdir -p build && cd build
        cmake .. \
            -DCMAKE_TOOLCHAIN_FILE=../../../ios-cmake/ios.toolchain.cmake \
            -DPLATFORM=OS64 \
            -GXcode \
            -DCMAKE_INSTALL_PREFIX="${prefix}"
        cmake --build . --config Release
        cmake --install . --config Release
    else
        ./configure --host=arm-apple-darwin --prefix="${prefix}" --enable-static --disable-shared
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

git clone --branch v${VERSION} ${REPO}.git ${SRC_DIR}/libqalculate
cd ${SRC_DIR}/libqalculate

mkdir -p ${BUILD_DIR}/ios/libqalculate && cd ${BUILD_DIR}/ios/libqalculate

cmake -DCMAKE_TOOLCHAIN_FILE=../../../ios-cmake/ios.toolchain.cmake \
      -DPLATFORM=OS64 \
      -GXcode \
      -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}/ios/libqalculate \
      -DCMAKE_FIND_ROOT_PATH="${INSTALL_DIR}/ios" \
      -DICU_ROOT=${INSTALL_DIR}/ios/icu \
      -DGMP_ROOT=${INSTALL_DIR}/ios/gmp \
      -DMPFR_ROOT=${INSTALL_DIR}/ios/mpfr \
      ${SRC_DIR}/libqalculate

cmake --build . --config Release --target install

echo "Build process completed successfully."
