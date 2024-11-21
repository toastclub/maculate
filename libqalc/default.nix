{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "my-build";
  version = "1.0";

  # Specify your source files here or fetch them from a repository
  src = ./.;

  buildInputs = [
    pkgs.perl
    pkgs.aria2
    pkgs.xz
    pkgs.autoconf
    pkgs.automake
    pkgs.libtool
    pkgs.texinfo
    pkgs.pkgconf
    pkgs.pkg-config
    pkgs.intltool
  ];

  # Override phases if necessary, or define custom ones
  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -r build/* $out/bin
  '';

  # Clean up any unnecessary files
  cleanPhase = ''
    make clean
  '';
}
