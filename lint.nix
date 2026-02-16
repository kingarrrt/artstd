{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (config.artstd) toolCfg;
in
{

  imports = [
    ./tools.nix
    ./treefmt.nix
  ];

  options.programs.shellcheck = {
    exclude = mkOption { type = with types; listOf int; };
    paths = mkOption { type = with types; listOf path; };
  };

  config = {

    programs =
      lib.genAttrs [ "deadnix" "ruff-check" "shellcheck" "statix" ]
        (_name: {
          enable = true;
        });

    settings.formatter = with pkgs; {

      flake-lock-dirty-inputs = {
        command = writers.writeBashBin "flake-lock-dirty-inputs-check" ''
          dirty=$(
            ${lib.getExe jq} --raw-output < $1 '.. | objects | select(has("dirtyRev")) | .url'
          )
          if [[ -n $dirty ]]; then
            echo -e >&2 "$1 has dirty inputs:\n"
            echo >&2 "$dirty"
            exit 1
          fi
        '';
        includes = [ "flake.lock" ];
      };

      flake-lock-dupe-inputs = {
        command = writers.writeBashBin "flake-lock-dupe-inputs-check" ''
          if grep -q _2 $1; then
            echo >&2 "$1 has duplicate inputs:\n"
            exit 1
          fi
        '';
        includes = [ "flake.lock" ];
      };

      markdownlint = {
        command = nodePackages.markdownlint-cli;
        options = [
          "-c"
          "${toolCfg.markdownlint}"
        ];
        includes = [ "*.md" ];
      };

      nil = {
        # TOGO: pending https://github.com/oxalica/nil/pull/127
        command = writers.writeBashBin "nil" ''
          errors=
          for file in "$@"; do
            errors+="$(${lib.getExe nil} diagnostics "$file" 2>&1)"
          done
          if [[ -n "$errors" ]]; then
            echo -e >&2 "$errors"
            exit 1
          fi
        '';
        includes = [ "*.nix" ];
      };

      shellcheck =
        let
          inherit (config.settings) formatter;
          cfg = formatter.shellcheck;
        in
        {
          command = writers.writeBashBin "shellcheck-shlib" ''
            ln -sf ${./.}/bin/shlib shlib
            ${lib.getExe pkgs.shellcheck} "$@"
          '';
          includes =
            lib.optionals config.programs.beautysh.enable formatter.beautysh.includes
            ++ lib.optionals config.programs.shfmt.enable formatter.shfmt.includes;
          paths = { };
          exclude = [
            2046 # Quote this to prevent word splitting
            2053 # Quote the right-hand side of == in [[ ]] to prevent glob matching
            2086 # Double quote to prevent globbing and word splitting
            2164 # Use 'popd ... || exit' or 'popd ... || return' in case popd fails
            2206 # Quote to prevent word splitting/globbing, or split robustly with mapfile or read -a
          ];
          options = [
            "--shell=bash"
            "--external-sources"
          ]
          ++ lib.mapAttrsToList (
            # use env var so this works with both treefmt and nvim
            env: path: "--source-path=\$${env}${path}"
          ) cfg.paths
          ++ [
            "--exclude=${
              builtins.concatStringsSep "," (
                map toString (builtins.sort (a: b: a < b) cfg.exclude)
              )
            }"
          ];
        };

      vint = {
        command = pkgs.vim-vint;
        includes = [
          "*.vim"
          ".vimrc.local"
        ];
      };

      yamllint = {
        command = pkgs.yamllint;
        options = [
          "-c"
          "${toolCfg.yamllint}"
        ];
        includes = [
          "*.yaml"
          "*.yml"
        ];
      };

    };

  };

}
