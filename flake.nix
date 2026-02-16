{
  description = "KingArrrt Engineering Standards";

  inputs = {
    artpkgs = {
      url = "git+file:///home/arthur/wrk/artdev/artpkgs";
      inputs = {
        flake-utils.follows = "flake-utils";
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixpkgs.url = "git+file:///home/arthur/wrk/ext/nixpkgs/unstable";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs =
    inputs:
    inputs.artpkgs.lib.flakeSet {
      inherit (inputs) self;
      name = "artstd";
      packages = pkgs: { default = pkgs.artstd; };
      checks = pkgs: {

        validate =
          (pkgs.writeShellApplication {
            name = "validate";
            runtimeInputs = with pkgs; [
              deadnix
              statix
              nixfmt
              lychee
              markdownlint-cli
              mdformat
              shellcheck
              shfmt
            ];
            text = ''
              set -euo pipefail

              echo "Validating Nix files..."
              deadnix --fail .
              statix check .
              nixfmt --check .

              echo "Validating Markdown files..."
              markdownlint .
              mdformat --check .

              echo "Validating links..."
              lychee --no-progress ./**/*.md
            '';
          }).overrideAttrs
            { __impure = true; };

      };
    }
    // {
      overlays.default = final: _prev: {
        artstd = final.callPackage ./. {
          rev = inputs.self.shortRev or inputs.self.dirtyShortRev or "dirty";
        };
      };
    };
}
