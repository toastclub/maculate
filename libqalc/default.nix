{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
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
  depsBuildBuild = [
    pkgs.stdenv.cc
  ];

  buildInputs = [
    pkgs.gettext
    pkgs.libiconv
  ];
  propagatedBuildInputs = [
    pkgs.libxml2
    pkgs.mpfr
    # we build icu statically to avoid dynamic linking to libcpp
    pkgs.pkgsStatic.icu
    pkgs.gmp
  ];

  configureFlags = [
    # we should fetch in swift
    "--without-libcurl"
    "--enable-compiled-definitions"
    # to avoid libcpp dylib
    "--disable-shared"
    "--enable-static"
  ];

  # todo: this is preferable, but it causes configure: error: C compiler cannot create executables
  #LDFLAGS = "-avoid-version";

  enableParallelBuilding = true;

  preConfigure = ''
    intltoolize -f
  '';

  # this code is not relevant
  patchPhase = ''
    substituteInPlace libqalculate/Calculator-plot.cc \
      --replace 'commandline = "gnuplot"' 'commandline = "${pkgs.gnuplot}/bin/gnuplot"' \
      --replace '"gnuplot - ' '"${pkgs.gnuplot}/bin/gnuplot - '
  '' + pkgs.lib.optionalString pkgs.stdenv.cc.isClang ''
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
    for lib in ${pkgs.gmp.out}/lib/libgmp.dylib \
        ${pkgs.mpfr.out}/lib/libmpfr.dylib \
        ${pkgs.pkgsStatic.icu}/lib/libicuuc.a \
        ${pkgs.pkgsStatic.icu}/lib/libicudata.a \
        ${pkgs.pkgsStatic.icu}/lib/libicui18n.a \
        ${pkgs.libxml2.out}/lib/libxml2.dylib \
        ${pkgs.libiconv.out}/lib/libiconv.dylib \
        ${pkgs.gettext.out}/lib/libintl.dylib; do
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
