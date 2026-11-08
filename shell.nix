{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "win10-start-dev";
  buildInputs = with pkgs; [
    cmake
    ninja
    pkg-config
    gcc
    qt6.qtbase
    qt6.qtdeclarative
  ];
}
