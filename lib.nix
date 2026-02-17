inputs: {

  flakeSet =
    {
      # inputs.self
      self,
      # std flake attrs
      apps ? _pkgs: { },
      checks ? _pkgs: { },
      packages ? _pkgs: { },
      # passed to `pkgs.mkShell` as `packages`
      devPkgs ? _pkgs: [ ],
      # cfgs for treefmt and treefmt lint (which extends base treefmt)
      fmtCfg ? ./treefmt.nix,
      lintCfg ? ./lint.nix,
      # appended to .nvim.local.lua
      nvimCfg ? "",
      # set in envrc
      env ? { },
      # NOTE: any change in args must be reflected in the removeAttrs call below
      ...
    }@args:
    let
      inherit (inputs.nixpkgs) lib;
    in
    (inputs.flake-utils.lib.eachSystem (import inputs.systems) (
      system:
      let

        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            # export fmt and lint
            (_final: _prev: {
              artstd-fmt = fmt;
              artstd-lint = lint-fail-on-change;
            })
          ]
          ++ [ inputs.self.overlays.default ]
          ++ lib.optionals (
            self != inputs.self && self ? overlays && self.overlays ? default
          ) [ self.overlays.default ];
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

        fmt = (treefmt pkgs (withself fmtCfg)).build.wrapper;

        lintcfg' = treefmt pkgs (withself lintCfg);
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
          lint = lintcfg'.build.check self;
        };

        packages = packages';

        # for `nix fmt`
        formatter = fmt;

        devShells.default = pkgs.mkShellNoCC {

          preferLocalBuild = true;

          inputsFrom = builtins.attrValues packages';

          packages = [
            fmt
            lint-fail-on-change
          ]
          ++ (builtins.attrValues lintcfg'.build.programs)
          ++ (devPkgs pkgs);

          shellHook =
            let

              inherit (lintcfg'.settings.formatter) shellcheck;

              # make .env
              dotenv = pkgs.writeText "artstd-env" (
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
              exrc = pkgs.writeText "artstd-nvim-local.lua" ''
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
                ${lib.optionalString (shellcheck.paths != [ ])
                  "vim.opt.path:prepend {${
                    builtins.concatStringsSep ", " (
                      lib.mapAttrsToList (
                        env: path: ''vim.env.${env} .. "${path}"''
                      ) shellcheck.paths
                    )
                  }}"
                }
                ${lib.optionalString (nvimCfg != "") nvimCfg}
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

      }

    ))
    # remaining args set direct on flake
    // builtins.removeAttrs args [
      "self"
      "apps"
      "checks"
      "packages"
      "devPkgs"
      "fmtCfg"
      "lintCfg"
      "nvimCfg"
      "env"
    ];

}
