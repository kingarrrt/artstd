{
  lib,
  stdenv,
  rev ? "dirty",
}:
stdenv.mkDerivation {

  pname = "artstd";

  version = "dev";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./README.md ];
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cp README.md $out/README.md
    sed -i "s/@REV@/${rev}/g" $out/README.md
  '';

}
