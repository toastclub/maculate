nix-build
rm -rf Qalculate/frameworks
mkdir -p Qalculate/frameworks
# add +w to all folders in frameworks
find Qalculate/frameworks -type d -exec chmod +w {} \;


# qalculate
cp result/lib/libqalculate.23.dylib ./libqalculate.dylib
chmod +w ./libqalculate.dylib
xcodebuild -create-xcframework -library ./libqalculate.dylib -headers result/include/libqalculate/ -output Qalculate/frameworks/LibQalculate.xcframework
rm ./libqalculate.dylib
# gmp
xcodebuild -create-xcframework -library result/lib/libgmp.dylib -headers result/include/gmp.h -output Qalculate/frameworks/GMP.xcframework
# mpfr
xcodebuild -create-xcframework -library result/lib/libmpfr.dylib -headers result/include/mpfr.h -output Qalculate/frameworks/MPFR.xcframework
#libxml2
xcodebuild -create-xcframework -library result/lib/libxml2.dylib -headers result/include/libxml2/ -output Qalculate/frameworks/LibXML2.xcframework
#libiconv
xcodebuild -create-xcframework -library result/lib/libiconv.dylib -output Qalculate/frameworks/LibIconv.xcframework
#libintl
xcodebuild -create-xcframework -library result/lib/libintl.dylib -output Qalculate/frameworks/LibIntl.xcframework

# qalculate fixups
find Qalculate/frameworks -type d -exec chmod +w {} \;
find Qalculate/frameworks/LibQalculate.xcframework -name "*.h" \
    -exec sed -i '' 's/<libqalculate\//</g' {} \;
mv Qalculate/frameworks/LibQalculate.xcframework/macos-arm64/Headers/qalculate.h Qalculate/frameworks/LibQalculate.xcframework/macos-arm64/Headers/LibQalculate.h
