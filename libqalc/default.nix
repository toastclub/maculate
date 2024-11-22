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
    pkgs.doxygen
  ];
  depsBuildBuild = [
    pkgs.stdenv.cc
  ];

  buildInputs = [
    pkgs.curl
    pkgs.gettext
    pkgs.libiconv
    pkgs.readline
  ];
  propagatedBuildInputs = [
    pkgs.libxml2
    pkgs.mpfr
    pkgs.icu
    pkgs.gmp
  ];

  configureFlags = [
    "--disable-shared"
    "--enable-static"
  ];

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

  preBuild = ''
    pushd docs/reference
    doxygen Doxyfile
    popd
  '';

  postInstall = ''
    # Ensure all headers from propagatedBuildInputs are copied to the include directory
    mkdir -p $out/include
    for dep in ${pkgs.lib.concatStringsSep " " (map (pkg: "${pkg.dev}/include") propagatedBuildInputs)}; do
      if [ -d "$dep" ]; then
        cp -r $dep/* $out/include/
      fi
    done
  '';

  meta = with pkgs.lib; {
    license = licenses.gpl2Plus;
    mainProgram = "qalc";
    platforms = platforms.all;
  };
}
