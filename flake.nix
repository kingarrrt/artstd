{

  inputs = {
    artpkgs = {
      url = "git+file:///home/arthur/wrk/artdev/artpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "git+file:///home/arthur/wrk/ext/nixpkgs/unstable";
  };

  # nixConfig.extra-experimental-features = [ "impure-derivations" ];

  outputs =
    inputs:
    inputs.artpkgs.lib.flakeSet {
      inherit (inputs) self;
      name = "artstd";
      packages = pkgs: { default = pkgs.artstd; };
    }
    // {

      overlays.default = _self: super: { artstd = super.callPackage ./. { }; };

      # devShells.default =
      #   with pkgs;
      #   mkShellNoCC {
      #     packages = [
      #       claude-code
      #       gemini-cli
      #     ];
      #   };
      #
      # checks.validate =
      #   pkgs.runCommand "validate-standard"
      #     {
      #
      #       __impure = true;
      #
      #       nativeBuildInputs = with pkgs; [
      #         curl
      #         jq
      #       ];
      #
      #       ANTHROPIC_API_KEY = builtins.getEnv "ANTHROPIC_API_KEY";
      #
      #     }
      #     ''
      #       [[ -n "$ANTHROPIC_API_KEY" ]] || {
      #         echo >&2 "ANTHROPIC_API_KEY not set"
      #         exit 1
      #       }
      #
      #       response=$(curl -sf https://api.anthropic.com/v1/messages \
      #         -H "x-api-key: $ANTHROPIC_API_KEY" \
      #         -H "anthropic-version: 2023-06-01" \
      #         -H "content-type: application/json" \
      #         -d "$(jq -n --arg doc "$(cat ${./README.md})" '{
      #           model: "claude-opus-4-latest",
      #           max_tokens: 1024,
      #           messages: [{
      #             role: "user",
      #             content: "Validate this engineering standards document. Check for:\n1. RFC 2119 keyword consistency (MUST/SHOULD/MAY usage)\n2. Internal contradictions\n3. Ambiguous requirements\n\nRespond with ONLY \"PASS\" if valid, or \"FAIL: <issues>\" if not.\n\n\($doc)"
      #           }]
      #         }')")
      #
      #       result=$(echo "$response" | jq -r '.content[0].text')
      #       echo "$result"
      #
      #       if echo "$result" | grep -q "^PASS"; then
      #         mkdir $out
      #         echo "$response" > $out/response.json
      #       else
      #         exit 1
      #       fi
      #     '';

    };

}
