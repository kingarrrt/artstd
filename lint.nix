{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    genAttrs
    getExe
    getExe'
    mapAttrsToList
    mkOption
    optionals
    types
    ;
  inherit (pkgs.writers) writeBashBin;
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
      genAttrs [ "deadnix" "ruff-check" "shellcheck" "statix" ]
        (_name: {
          enable = true;
        });

    settings.formatter = {

      flake-lock-dirty-inputs = {
        command = writeBashBin "flake-lock-dirty-inputs-check" ''
          dirty=$(
            ${getExe pkgs.jq} --raw-output < $1 '.. | objects | select(has("dirtyRev")) | .url'
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
        command = writeBashBin "flake-lock-dupe-inputs-check" ''
          if grep -q _2 $1; then
            echo >&2 "$1 has duplicate inputs - check your `follows`"
            exit 1
          fi
        '';
        includes = [ "flake.lock" ];
      };

      markdownlint = {
        command = pkgs.nodePackages.markdownlint-cli;
        options = [
          "-c"
          "${toolCfg.markdownlint}"
        ];
        includes = [ "*.md" ];
      };

      nil = {
        # TOGO: pending https://github.com/oxalica/nil/pull/127
        command = writeBashBin "nil" ''
          errors=
          for file in "$@"; do
            errors+="$(${getExe pkgs.nil} diagnostics "$file" 2>&1)"
          done
          if [[ -n "$errors" ]]; then
            echo -e >&2 "$errors"
            exit 1
          fi
        '';
        includes = [ "*.nix" ];
      };

      proselint = {
        # replace code blocks with empty lines to preserve line numbering
        # s/./ /g; replaces content with spaces to preserve column accuracy
        # :a; s/`[^`]*`/ /; ta; handles multiple inline code blocks per line
        command = writeBashBin "proselint" ''
          ${getExe pkgs.gnused} '/^```/,/^```/ { /^```/! s/./ /g; }; :a; s/`[^`]*`/ /; ta' "$@" \
            | ${getExe' pkgs.proselint "proselint"} --config ${toolCfg.proselint}
        '';
        includes = [ "*.md" ];
      };

      shellcheck =
        let
          inherit (config.settings) formatter;
          cfg = formatter.shellcheck;
        in
        {
          command = writeBashBin "shellcheck" ''
            ${getExe pkgs.shellcheck} "$@"
          '';
          includes =
            optionals config.programs.beautysh.enable formatter.beautysh.includes
            ++ optionals config.programs.shfmt.enable formatter.shfmt.includes;
          paths = { };
          exclude = [
            2046 # Quote this to prevent word splitting
            2053 # Quote the right-hand side of == in [[ ]] to prevent glob matching
            2086 # Double quote to prevent globbing and word splitting
            2206 # Quote to prevent word splitting/globbing, or split robustly with mapfile or read -a
          ];
          options = [
            "--shell=bash"
            "--external-sources"
          ]
          ++ mapAttrsToList (
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
