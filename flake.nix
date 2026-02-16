{

  description = "KingArrrt Engineering Standards";

  nixConfig = {
    extra-substituters = [ "https://artstd.cachix.org" ];
    extra-trusted-public-keys = [
      "artstd.cachix.org-1:Y0FINCDWAil4Y/0dnsY9JXKuHIgkjEb+vgVop6v3+IM="
    ];
  };

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # transitive
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };

    systems.url = "github:nix-systems/default";

    treefmt = {
      url = "github:numtide/treefmt";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        blueprint.inputs = {
          nixpkgs.follows = "nixpkgs";
          systems.follows = "systems";
        };
      };
    };

  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
      self-lib = import ./lib.nix inputs;
    in
    self-lib.flakeSet {
      inherit (inputs) self;
      name = "artstd";
      checks = pkgs: {
        links = pkgs.runCommand "link-check" {
          __impure = true;
          nativeBuildInputs = with pkgs; [ lychee ];
        } "lychee --no-progress ${./.}**/*.md | tee $out";
      };
      packages = pkgs: { default = pkgs.artstd; };
    }
    // {

      lib = self-lib;

      nixosModules.artstd.home-manager.sharedModules = [
        (
          { config, ... }:
          with config.artstd.tool-config;
          {
            imports = [ ./tool-config.nix ];
            home.file = {
              ".markdownlintrc".source = markdownlint;
            };
            xdg.configFile = {
              "yamlfix.toml".source = yamlfix;
              "yamllint/config".source = yamllint;
            };
          }
        )
      ];

      overlays.default = lib.composeManyExtensions [
        (import ./overlay.nix)
        (final: _prev: {
          artstd = final.callPackage ./. {
            rev = inputs.self.shortRev or inputs.self.dirtyShortRev or "dirty";
          };
        })
      ];

    };
}
