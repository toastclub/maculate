###################
#   Basic Setup   #
###################

FRAMEWORKS_DIR=Qalculate/frameworks

nix-build
rm -rf $FRAMEWORKS_DIR
mkdir -p $FRAMEWORKS_DIR
# add +w to all folders in frameworks, as nix may have made them read-only even after a copy
find $FRAMEWORKS_DIR -type d -exec chmod +w {} \;

###################
#   Build Steps   #
###################

# right now the version is hardcoded, see todo in default.nix
# if this is not set, macOS will not be able to find the dylibs, as it is
# looking for libqalculate.23.dylib, not libqalculate.dylib
# it may find the version inside nix, but it will fail due to being signed with
# a different certificate than Toastcat LLC.
# You can actually use the "Disable Library Validation" entitlement, but this
# means that the app will only work on your machine, and not on others.

# qalculate
# rename for convenience
xcodebuild -create-xcframework \
    -library result/lib/libqalculate.a \
    -headers result/include/libqalculate/ \
    -output $FRAMEWORKS_DIR/LibQalculate.xcframework
# gmp       headers: REQUIRED
xcodebuild -create-xcframework \
    -library result/lib/libgmp.a \
    -headers result/include/gmp.h \
    -output $FRAMEWORKS_DIR/GMP.xcframework
# mpfr      headers: REQUIRED
xcodebuild -create-xcframework \
    -library result/lib/libmpfr.a \
    -headers result/include/mpfr.h \
    -output $FRAMEWORKS_DIR/MPFR.xcframework
# libxml2   headers: NOT needed
xcodebuild -create-xcframework \
    -library result/lib/libxml2.2.dylib \
    -output $FRAMEWORKS_DIR/LibXML2.xcframework
#libiconv   headers: NONE NOT NEEDED
xcodebuild -create-xcframework \
    -library result/lib/libiconv.2.dylib \
    -output $FRAMEWORKS_DIR/LibIconv.xcframework
#libintl    headers: NOT NEEDED
xcodebuild -create-xcframework \
    -library result/lib/libintl.8.dylib \
    -output $FRAMEWORKS_DIR/LibIntl.xcframework
# icu       headers: NONE
for lib in icuuc icudata icui18n; do
    xcodebuild -create-xcframework \
        -library result/lib/lib${lib}.a \
        -output $FRAMEWORKS_DIR/ICU${lib}.xcframework
done

###################
#  Code Signing   #
###################

# find all dylibs and sign them.
# hardcoded to Toastcat LLC. You can change this to your own certificate.
find $FRAMEWORKS_DIR -name "*.dylib" -exec codesign --force \
    --timestamp --sign "Apple Development: Evan Boehs (668LYMH4FH)" {} \;

find $FRAMEWORKS_DIR -name "*.a" -exec chmod +w {} \; -exec codesign --force \
    --timestamp --sign "Apple Development: Evan Boehs (668LYMH4FH)" {} \;

###################
#   Post-Process  #
###################

# qalculate fixups
find $FRAMEWORKS_DIR -type d -exec chmod +w {} \;
# give +w on all .a files
find $FRAMEWORKS_DIR/LibQalculate.xcframework -name "*.h" \
    -exec sed -i '' 's/<libqalculate\//</g' {} \;
mv $FRAMEWORKS_DIR/LibQalculate.xcframework/macos-arm64/Headers/qalculate.h $FRAMEWORKS_DIR/LibQalculate.xcframework/macos-arm64/Headers/LibQalculate.h
