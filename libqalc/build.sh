###################
#   Basic Setup   #
###################

nix-build
rm -rf Qalculate/frameworks
mkdir -p Qalculate/frameworks
# add +w to all folders in frameworks, as nix may have made them read-only even after a copy
find Qalculate/frameworks -type d -exec chmod +w {} \;

###################
#   Build Steps   #
###################

# qalculate
# rename for convenience
cp result/lib/libqalculate.23.dylib ./libqalculate.dylib
chmod +w ./libqalculate.dylib
xcodebuild -create-xcframework -library ./libqalculate.dylib -headers result/include/libqalculate/ -output Qalculate/frameworks/LibQalculate.xcframework
rm ./libqalculate.dylib
# gmp       headers: REQUIRED
xcodebuild -create-xcframework -library result/lib/libgmp.dylib -headers result/include/gmp.h -output Qalculate/frameworks/GMP.xcframework
# mpfr      headers: REQUIRED
xcodebuild -create-xcframework -library result/lib/libmpfr.dylib -headers result/include/mpfr.h -output Qalculate/frameworks/MPFR.xcframework
# libxml2   headers: NOT needed
xcodebuild -create-xcframework -library result/lib/libxml2.dylib -output Qalculate/frameworks/LibXML2.xcframework
#libiconv   headers: NONE NOT NEEDED
#xcodebuild -create-xcframework -library result/lib/libiconv.dylib -output Qalculate/frameworks/LibIconv.xcframework
#libintl    headers: NOT NEEDED
xcodebuild -create-xcframework -library result/lib/libintl.dylib -output Qalculate/frameworks/LibIntl.xcframework
#icu       headers: NONE
#xcodebuild -create-xcframework -library result/lib/libicuuc.dylib -output Qalculate/frameworks/ICU.xcframework
#

###################
#   Post-Process  #
###################

# qalculate fixups
find Qalculate/frameworks -type d -exec chmod +w {} \;
find Qalculate/frameworks/LibQalculate.xcframework -name "*.h" \
    -exec sed -i '' 's/<libqalculate\//</g' {} \;
mv Qalculate/frameworks/LibQalculate.xcframework/macos-arm64/Headers/qalculate.h Qalculate/frameworks/LibQalculate.xcframework/macos-arm64/Headers/LibQalculate.h
