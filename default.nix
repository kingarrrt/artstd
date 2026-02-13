{ lib, stdenv }:
stdenv.mkDerivation (finalAttrs: {

  pname = "artstd";

  version = "dev";

  src =
    with lib.fileset;
    toSource {
      root = ./.;
      fileset = unions [ ./README.md ];
    };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cp README.md $out
  '';

})
