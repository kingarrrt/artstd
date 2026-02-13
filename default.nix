{
  lib,
  stdenv,
  rev ? "dirty",
  pandoc,
}:
stdenv.mkDerivation {

  pname = "artstd";

  version = rev;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./README.md ];
  };

  nativeBuildInputs = [ pandoc ];

  buildPhase = ''
    runHook preBuild

    # Substitute rev and create man page
    sed "s/@REV@/${rev}/g" README.md > README.rev.md
    pandoc -s README.rev.md --metadata=title:"artstd" -t man -o artstd.1

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install man page
    mkdir -p $out/share/man/man1
    install -m 444 artstd.1 $out/share/man/man1/

    # Install README
    mkdir -p $out/share/doc/$pname
    install -m 444 README.rev.md $out/share/doc/$pname/README.md

    runHook postInstall
  '';

}
