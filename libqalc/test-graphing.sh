#!/bin/bash
# Run the native sampler checks after build-apple.sh macosx.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")" && pwd)
FRAMEWORKS="$ROOT/Qalculate/frameworks"
mkdir -p "$ROOT/.build/tests"
"$(xcrun -f clang++)" -std=c++17 -isysroot "$(xcrun --sdk macosx --show-sdk-path)" \
    -I"$ROOT/result/include" -I"$ROOT/result/include/libqalculate" \
    "$ROOT/tests/graphing.cpp" "$ROOT/Qalculate/graphing.cpp" \
    "$ROOT/Qalculate/main.cpp" "$ROOT/Qalculate/internal.cpp" \
    "$FRAMEWORKS/LibQalculate.xcframework/macos-arm64/libqalculate.a" \
    "$FRAMEWORKS/MPFR.xcframework/macos-arm64/libmpfr.a" \
    "$FRAMEWORKS/GMP.xcframework/macos-arm64/libgmp.a" \
    "$FRAMEWORKS/ICUicui18n.xcframework/macos-arm64/libicui18n.a" \
    "$FRAMEWORKS/ICUicuuc.xcframework/macos-arm64/libicuuc.a" \
    "$FRAMEWORKS/ICUicudata.xcframework/macos-arm64/libicudata.a" \
    -lxml2 -liconv -o "$ROOT/.build/tests/graphing"
"$ROOT/.build/tests/graphing"
