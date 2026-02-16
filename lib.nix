inputs: {

  flakeSet =
    {
      self,
      name,
      apps ? _pkgs: { },
      checks ? _pkgs: { },
      packages ? _pkgs: { },
      devpkgs ? _pkgs: [ ],
      fmtcfg ? ./treefmt.nix,
      lintcfg ? ./lint.nix,
      nvimcfg ? "",
      env ? { },
    }:
    let
      inherit (inputs.nixpkgs) lib;
    in
    inputs.flake-utils.lib.eachSystem (import inputs.systems) (
      system:
      let

        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (_final: _prev: { artstd-lint = lint-fail-on-change; })
          ]
          ++ lib.optionals (self ? overlays && self.overlays ? default) [
            self.overlays.default
          ];
        };

        treefmt =
          pkgs: config:
          (inputs.treefmt.inputs.treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            imports = [ config ];
          }).config;

        withself =
          fmtcfg:
          if builtins.typeOf fmtcfg == "lambda" then fmtcfg inputs.self else fmtcfg;

        formatter = (treefmt pkgs (withself fmtcfg)).build.wrapper;

        lintcfg' = treefmt pkgs (withself lintcfg);
        lint = lintcfg'.build.wrapper;
        lint-fail-on-change = pkgs.scriptWrapper {
          override = "lint";
          package = lint;
          script = ''set -- --fail-on-change  "$@"'';
        };

        packages' = packages pkgs;

      in
      {

        apps = apps pkgs;

        checks = (checks pkgs) // {
          # lint includes fmt
          lint = lintcfg'.build.check self;
        };

        devShells.default = pkgs.mkShellNoCC {

          preferLocalBuild = true;

          inputsFrom = builtins.attrValues packages';

          packages = [
            formatter
            lint-fail-on-change
          ]
          ++ (builtins.attrValues lintcfg'.build.programs)
          ++ (devpkgs pkgs);

          shellHook =
            let

              inherit (lintcfg'.settings.formatter) shellcheck;

              # make .env
              dotenv = pkgs.writeText "${name}-env" (
                lib.concatLines (
                  lib.mapAttrsToList (name: value: ''${name}="${toString value}"'') (
                    env
                    # make shellcheck use our config
                    // {
                      SHELLCHECK_OPTS = builtins.concatStringsSep " " shellcheck.options;
                    }
                  )
                )
              );

              # nvim compat:
              # - bashls/shellcheck
              # - paths
              exrc = pkgs.writeText "${name}-nvim-local.lua" ''
                local ctx = require("exrc").init()
                ctx:lsp_setup {
                  bashls = function(config)
                    config.settings = vim.tbl_deep_extend("force", config.settings, {
                      bashIde = {
                        shellcheckArguments = {
                          ${builtins.concatStringsSep "\n          " (
                            map (option: ''"${option}",'') shellcheck.options
                          )}
                        }
                      }
                    })
                  end,
                }
                vim.opt.path:prepend {${
                  builtins.concatStringsSep ", " (
                    lib.mapAttrsToList (
                      env: path: ''vim.env.${env} .. "${path}"''
                    ) shellcheck.paths
                  )
                }}
                ${nvimcfg}
              '';

              # lint is the git hook (it includes fmt)
              hooks = inputs.git-hooks.lib.${system}.run {
                src = self;
                hooks.lint = {
                  enable = true;
                  entry = toString (
                    let
                      git = lib.getExe pkgs.git;
                    in
                    pkgs.writers.writeBash "lint" ''
                      ${lib.getExe lint} --tree-root $(${git} rev-parse --show-toplevel) "$@"
                      ${git} diff --exit-code --ignore-submodules
                    ''
                  );
                };

              };
            in
            ''
              ${hooks.shellHook}
              ln -sf ${dotenv} .env
              # copy not link because nvim exrc gets context pwd from it
              cp -f ${exrc} .nvim.local.lua
            '';
        };

        # for `nix fmt`
        inherit formatter;

        packages = packages';

      }

    );

}
