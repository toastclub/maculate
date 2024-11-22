{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "libmaculate";
  version = "0.0.0";

  src = ./.;

  depsBuildBuild = [
    pkgs.stdenv.cc
  ];

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    pkgs.autoreconfHook
  ];

  buildInputs = [
    (pkgs.callPackage ./libqalculate.nix {})
  ];

  enableParallelBuilding = true;

  meta = with pkgs.lib; {
    license = licenses.gpl2Plus;
    mainProgram = "qalc";
    platforms = platforms.all;
  };
}
