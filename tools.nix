{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
in
{

  options.artstd = {

    line-length = mkOption {
      default = 88;
      type = types.int;
    };

    toolCfg = mkOption {

      default = {

        markdownlint = pkgs.writers.writeJSON "markdownlint.json" {
          MD013.line_length = config.artstd.line-length;
          MD040 = false; # fenced-code-language
          MD046 = false; # code-block-style
        };

        proselint = pkgs.writers.writeJSON "proselint.json" {
          checks = {
            "annotations.misc" = false;
          };
        };

        yamlfix = pkgs.writers.writeTOML "yamlfix.toml" {
          explicit_start = false;
          line_length = config.artstd.line-length;
          sequence_style = "keep_style";
          section_whitelines = 1;
          whitelines = 1;
        };

        yamllint = pkgs.writers.writeYAML "yamllint.yaml" {
          extends = "default";
          rules = {
            comments-indentation = "disable";
            document-start = "disable";
            key-ordering = "disable";
            line-length = "disable";
          };
        };

      };

      type = types.attrs;

    };

  };

}
