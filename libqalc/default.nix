{ pkgs ? import <nixpkgs> {}, pkgsCross ? pkgs.pkgsCross, target ? "macOS" }:

let
  platform = if target == "ios" then pkgsCross.iphone64 // {
    darwinSdkVersion = "11.0";
  }
  else pkgs;
in
platform.stdenv.mkDerivation rec {
  pname = "libqalculate";
  version = "5.3.0";

  src = pkgs.fetchFromGitHub {
    owner = "qalculate";
    repo = "libqalculate";
    rev = "v${version}";
    hash = "sha256-YNw6oFjrbYifIlAF2fz+htT1PIk9oEn7nBrnIZIR7DE=";
  };

  nativeBuildInputs = [
    pkgs.intltool
    pkgs.pkg-config
    pkgs.autoreconfHook
  ];

  buildInputs = with platform; [
    gettext
    libiconv
    apple-sdk_11
  ];


  propagatedBuildInputs = with platform; [
    libxml2
    mpfr
    # we build icu statically to avoid dynamic linking to libcpp
    pkgsStatic.icu
    gmp
    apple-sdk_11
  ];

  configureFlags = [
    # we should fetch in swift
    "--without-libcurl"
    "--enable-compiled-definitions"
    # to avoid libcpp dylib
    "--disable-shared"
    "--enable-static"
  ];

  enableParallelBuilding = true;

  preConfigure = ''
    intltoolize -f
  '';

  patchPhase = pkgs.lib.optionalString pkgs.stdenv.cc.isClang ''
    substituteInPlace src/qalc.cc \
      --replace 'printf(_("aborted"))' 'printf("%s", _("aborted"))'
  '';

  postInstall = ''
    # Ensure all headers from propagatedBuildInputs are copied to the include directory
    mkdir -p $out/include
    for dep in ${pkgs.lib.concatStringsSep " " (map (pkg: "${pkg.dev}/include") propagatedBuildInputs)}; do
      if [ -d "$dep" ]; then
        cp -r $dep/* $out/include/
      fi
    done

    # purge the docs, which we have no use for
    rm -rf $out/share/doc
    rm -rf $out/share/locale
    mkdir -p $out/lib
    for lib in ${platform.gmp.out}/lib/libgmp.dylib \
        ${platform.mpfr.out}/lib/libmpfr.dylib \
        ${platform.pkgsStatic.icu}/lib/libicuuc.a \
        ${platform.pkgsStatic.icu}/lib/libicudata.a \
        ${platform.pkgsStatic.icu}/lib/libicui18n.a \
        ${platform.libxml2.out}/lib/libxml2.dylib \
        ${platform.libiconv.out}/lib/libiconv.dylib \
        ${platform.gettext.out}/lib/libintl.dylib; do
      target=$(readlink "$lib" || basename "$lib")
      cp "$lib" "$out/lib/$target"
    done

    # remove the .la files
    find $out -name "*.la" -type f -delete
  '';

  meta = with pkgs.lib; {
    license = licenses.gpl2Plus;
    mainProgram = "qalc";
    platforms = platforms.all;
  };
}
