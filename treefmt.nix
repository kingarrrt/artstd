{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (config.artstd) toolCfg;
  inherit (lib)
    genAttrs
    getExe
    getExe'
    mkForce
    mkIf
    ;
in
{

  imports = [ ./tools.nix ];

  programs =
    genAttrs [ "jsonfmt" "nixfmt" "ruff-format" "taplo" ] (_name: {
      enable = true;
    })
    // {
      shfmt.enable = !config.programs.beautysh.enable;
    };

  settings = {

    # force override defaults which exclude .gitignore
    excludes = mkForce [ "*.patch" ];

    formatter = {

      mdformat = {
        command = pkgs.python3.pkgs.mdformat;
        includes = [ "*.md" ];
        options = [
          "--wrap"
          "${toString config.artstd.line-length}"
        ];
      };

      nixfmt = {
        # treefmt references nixfmt-rfc-style which gives a warning on nixpkgs-unstable
        command = getExe pkgs.nixfmt;
        options = [
          "--width"
          # default is 100, is not a hard limit - this makes it in effect 95
          "77"
          "--strict"
        ];
      };

      shfmt = mkIf config.programs.shfmt.enable {
        includes = [
          # FIXME: pattern for all bins???
          "bin/*"
          "**/bin/*"
          ".env*"
        ];
      };

      sorted = {
        command =
          let
            sort = getExe' pkgs.coreutils "sort";
          in
          pkgs.writers.writeBashBin "sorted" ''
            ${sort} --check=quiet $1 || ${sort} $1 | ${getExe' pkgs.moreutils "sponge"} $1
          '';
        includes = [ "*gitignore" ];
      };

      # FIXME: leaves whitespace.XXXXXX files in PWD
      whitespace = {
        # make this run first
        priority = -1;
        command =
          let
            sed = "${getExe pkgs.gnused} -e 's/[[:space:]]*$//' -e ' \${/^$/d;}' ";
            strip = pkgs.writers.writeBash "strip" ''
              path="$1"
              tmp=$(mktemp --tmpdir -t whitespace.XXXXXX)
              ${sed} "$path" > $tmp
              if ${getExe' pkgs.diffutils "diff"} -q "$path" $tmp >/dev/null; then
                rm $tmp
              else
                mode=$(${getExe' pkgs.coreutils "stat"} --format=%a "$path")
                mv $tmp "$path"
                ${getExe' pkgs.coreutils "chmod"} $mode "$path"
              fi
            '';
          in
          pkgs.writers.writeBashBin "whitespace" ''
            if [[ -p /dev/stdin ]]; then
              ${sed} "$@"
            elif [[ $# -gt 1 ]]; then
              ${getExe' pkgs.moreutils "parallel"} ${strip} -- "$@"
            else
              ${strip} "$@"
            fi
          '';
        includes = [ "*" ];
      };

      yamlfix = {
        command = getExe' pkgs.python3.pkgs.yamlfix "yamlfix";
        options = [
          "--config-file"
          "${toolCfg.yamlfix}"
        ];
        includes = [
          "*.yaml"
          "*.yml"
        ];
      };

    };

  };

}
