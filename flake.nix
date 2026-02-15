{
  description = "KingArrrt Engineering Standards";

  inputs = {
    artpkgs = {
      url = "git+file:///home/arthur/wrk/artdev/artpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "git+file:///home/arthur/wrk/ext/nixpkgs/unstable";
    systems.url = "github:nix-systems/default";
    flake-utils.url = "github:numtide/flake-utils";
  };

  nixConfig.extra-experimental-features = [ "impure-derivations" ];

  outputs = inputs: let
      inherit (inputs) self;
    in
    {
      overlays.default = _final: prev: {
        artstd = prev.callPackage ./. {
          rev = self.shortRev or self.dirtyShortRev or "dirty";
        };
      };
    }
    // inputs.flake-utils.lib.eachSystem (import inputs.systems) (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.callPackage ./. {
          rev = self.shortRev or self.dirtyShortRev or "dirty";
        };

        checks = {
          validate-claude =
            let
              prompt = ''
                Validate this engineering standards document. Check for:
                1. RFC 2119 keyword consistency (MUST/SHOULD/MAY usage)
                2. Internal contradictions
                3. Ambiguous requirements

                Respond with ONLY "PASS" if valid, or "FAIL: <issues>" if not.

                ${builtins.readFile ./README.md}
              '';
              payload = builtins.toJSON {
                model = "claude-opus-4-latest";
                max_tokens = 1024;
                messages = [
                  {
                    role = "user";
                    content = prompt;
                  }
                ];
              };
            in
            pkgs.runCommand "validate-claude"
              {
                __impure = true;
                nativeBuildInputs = with pkgs; [
                  curl
                  jq
                ];
                ANTHROPIC_API_KEY = builtins.getEnv "ANTHROPIC_API_KEY";
              }
              ''
                [[ -n "$ANTHROPIC_API_KEY" ]] || {
                  echo >&2 "ANTHROPIC_API_KEY not set"
                  exit 1
                }

                response=$(curl -sf https://api.anthropic.com/v1/messages \
                  -H "x-api-key: $ANTHROPIC_API_KEY" \
                  -H "anthropic-version: 2023-06-01" \
                  -H "content-type: application/json" \
                  -d ${pkgs.lib.escapeShellArg payload})

                result=$(echo "$response" | jq -r '.content[0].text')
                echo "$result"

                if echo "$result" | grep -q "^PASS"; then
                  mkdir $out
                  echo "$response" > $out/response.json
                else
                  exit 1
                fi
              '';

          validate-markdown =
            let
              mdlintConfig = pkgs.writeText "markdownlint.json" (builtins.toJSON {
                line-length = {
                  line_length = 88;
                  code_blocks = false;
                  tables = false;
                };
              });
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
                mdformat --wrap 88 --check ${./README.md}
                mkdir $out
              '';

          validate-links = pkgs.runCommand "validate-links"
            {
              __impure = true;
              nativeBuildInputs = with pkgs; [ lychee ];
            }
            ''
              lychee --no-progress ${./README.md}
              mkdir $out
            '';
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            claude-code
            gemini-cli
          ];
        };
      }
    );
}