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
      packages = pkgs: {

        default = pkgs.artstd;

        validate-std = pkgs.writeShellApplication {
          name = "validate-std";
          runtimeInputs = with pkgs; [
            deadnix
            statix
            nixfmt
            markdownlint-cli
            mdformat
            shellcheck
            shfmt
          ];
          text = ''
            set -eo pipefail
            echo "Checking Nix files..."
            deadnix --fail .
            statix check .
            nixfmt --check .

            echo "Checking Markdown files..."
            markdownlint .
            mdformat --check .

            echo "Checking Shell scripts..."
            mapfile -t scripts < <(find . -name "*.sh")
            if [[ ''${#scripts[@]} -gt 0 ]]; then
              shellcheck "''${scripts[@]}"
              shfmt -d "''${scripts[@]}"
            fi

            echo "Standards check passed."
          '';
        };

      };
      checks = pkgs: {

        validate-markdown =
          let
            mdlintConfig = pkgs.writeText "markdownlint.json" (
              builtins.toJSON {
                line-length = {
                  line_length = 88;
                  code_blocks = false;
                  tables = false;
                };
              }
            );
          in
          pkgs.runCommand "validate-markdown"
            {
              nativeBuildInputs = with pkgs; [
                markdownlint-cli
                mdformat
              ];
            }
            ''
              markdownlint --config ${mdlintConfig} ${./README.md}
              mdformat --wrap 88 --check ${./README.md} | tee $out
            '';

        validate-links =
          pkgs.runCommand "validate-links"
            {
              __impure = true;
              nativeBuildInputs = with pkgs; [ lychee ];
            }
            ''
              lychee --no-progress ${./README.md}
              mkdir $out
            '';

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
