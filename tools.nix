{ lib, pkgs, ... }:
let
  inherit (lib) mkOption types;
in
{

  options.artstd.toolCfg = mkOption {

    default = {

      markdownlint = pkgs.writers.writeJSON "markdownlint.json" {
        MD013.line-length = 88;
        MD040 = false; # fenced-code-language
        MD046 = false; # code-block-style
      };

      yamlfix = pkgs.writers.writeTOML "yamlfix.toml" {
        explicit_start = false;
        line_length = 100;
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

}
