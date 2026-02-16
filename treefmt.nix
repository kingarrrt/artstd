{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (config.artstd) tool-config;
in
{

  imports = [ ./tool-config.nix ];

  programs =
    lib.genAttrs [ "jsonfmt" "nixfmt" "ruff-format" "taplo" ] (_name: {
      enable = true;
    })
    // {
      shfmt.enable = !config.programs.beautysh.enable;
    };

  settings = {

    # force override defaults which exclude .gitignore
    excludes = lib.mkForce [ "*.patch" ];

    formatter = with pkgs; {

      mdformat = {
        command = python3.pkgs.mdformat;
        includes = [ "*.md" ];
        options = [
          "--wrap"
          "88"
        ];
      };

      nixfmt.options = [
        "--width"
        # default is 100, is not a hard limit - this makes it in effect 95
        "77"
        "--strict"
      ];

      shfmt = lib.mkIf config.programs.shfmt.enable {
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
            sort = lib.getExe' coreutils "sort";
          in
          writers.writeBashBin "sorted" ''
            ${sort} --check=quiet $1 || ${sort} $1 | ${lib.getExe' moreutils "sponge"} $1
          '';
        includes = [ "*gitignore" ];
      };

      # FIXME: leaves whitespace.XXXXXX files in pwd
      whitespace = {
        # make this run first
        priority = -1;
        command =
          let
            sed = "${lib.getExe gnused} -e 's/[[:space:]]*$//' -e ' \${/^$/d;}' ";
            strip = writers.writeBash "strip" ''
              path="$1"
              tmp=$(mktemp --tmpdir -t whitespace.XXXXXX)
              ${sed} "$path" > $tmp
              if ${lib.getExe' diffutils "diff"} -q "$path" $tmp >/dev/null; then
                rm $tmp
              else
                mode=$(${lib.getExe' coreutils "stat"} --format=%a "$path")
                mv $tmp "$path"
                ${lib.getExe' coreutils "chmod"} $mode "$path"
              fi
            '';
          in
          writers.writeBashBin "whitespace" ''
            if [[ -p /dev/stdin ]]; then
              ${sed} "$@"
            elif [[ $# -gt 1 ]]; then
              ${lib.getExe' moreutils "parallel"} ${strip} -- "$@"
            else
              ${strip} "$@"
            fi
          '';
        includes = [ "*" ];
      };

      yamlfix = {
        command = lib.getExe' python3.pkgs.yamlfix "yamlfix";
        options = [
          "--config-file"
          "${tool-config.yamlfix}"
        ];
        includes = [
          "*.yaml"
          "*.yml"
        ];
      };

    };

  };

}
