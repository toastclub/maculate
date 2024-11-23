{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "libqalculate";
  version = "5.1.1";

  src = pkgs.fetchFromGitHub {
    owner = "qalculate";
    repo = "libqalculate";
    rev = "v${version}";
    hash = "sha256-cmH92gdQ+fmtOLgx5ibKqLZaQFzx2z+GuXhR62dtftk=";
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
  ];
  propagatedBuildInputs = [
    pkgs.libxml2
    pkgs.mpfr
    pkgs.icu
    pkgs.gmp
  ];

  configureFlags = [
    "--without-libcurl"
    "--enable-compiled-definitions"
  ];

  # todo: this is preferable, but it causes configure: error: C compiler cannot create executables
  #LDFLAGS = "-avoid-version";

  enableParallelBuilding = true;

  preConfigure = ''
    intltoolize -f
  '';

  patchPhase = ''
    substituteInPlace libqalculate/Calculator-plot.cc \
      --replace 'commandline = "gnuplot"' 'commandline = "${pkgs.gnuplot}/bin/gnuplot"' \
      --replace '"gnuplot - ' '"${pkgs.gnuplot}/bin/gnuplot - '
  '' + pkgs.lib.optionalString pkgs.stdenv.cc.isClang ''
    substituteInPlace src/qalc.cc \
      --replace 'printf(_("aborted"))' 'printf("%s", _("aborted"))'
  '';

  /*preBuild = ''
    pushd docs/reference
    doxygen Doxyfile
    popd
  '';*/

  postInstall = ''
    # Ensure all headers from propagatedBuildInputs are copied to the include directory
    mkdir -p $out/include
    for dep in ${pkgs.lib.concatStringsSep " " (map (pkg: "${pkg.dev}/include") propagatedBuildInputs)}; do
      if [ -d "$dep" ]; then
        cp -r $dep/* $out/include/
      fi
    done

    rm -rf $out/share/doc
    rm -rf $out/share/locale
    mkdir -p $out/lib
    for lib in ${pkgs.gmp.out}/lib/libgmp.dylib \
           ${pkgs.mpfr.out}/lib/libmpfr.dylib \
           ${pkgs.icu.out}/lib/libicuuc.dylib \
           ${pkgs.icu.out}/lib/libicudata.dylib \
           ${pkgs.icu.out}/lib/libicui18n.dylib \
           ${pkgs.libxml2.out}/lib/libxml2.dylib \
           ${pkgs.gettext.out}/lib/libintl.dylib; do
      target=$(readlink "$lib" || basename "$lib")
      cp "$lib" "$out/lib/$target"
    done
    # iconv is only used for the cli
    #cp ${pkgs.libiconv.out}/lib/libiconv.dylib $out/lib/

    # remove the .la files
    find $out -name "*.la" -type f -delete
  '';

  meta = with pkgs.lib; {
    license = licenses.gpl2Plus;
    mainProgram = "qalc";
    platforms = platforms.all;
  };
}
