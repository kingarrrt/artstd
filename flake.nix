{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let

        # Identity-compliant model list with restored documentation
        models = [
          # Flagship - Gemini 3 Series
          "gemini-3-pro-preview" # 2M Context | ~100 prompts/day | Advanced reasoning
          "gemini-3-flash-preview" # 1M Context | General access | High-speed multimodal
          "gemini-3-pro-image-preview" # Reasoning-enhanced vision | 30 images/month
          "gemini-3-deep-think" # 1M Context | ~50 prompts/day | Specialized deep logic

          # Stable Production - Gemini 2.5 Series
          "gemini-2.5-pro" # 1M Context | 15 RPM | Mature reasoning
          "gemini-2.5-flash" # 1M Context | 200 RPM | Versatile speed/logic
          "gemini-2.5-flash-lite" # 1M Context | 200 RPM | Cost-optimized throughput
          "gemini-2.5-flash-image" # 2,000 images/day | Native vision/generation

          # Real-time & Specialized
          "gemini-live-2.5-flash-native-audio" # ~2 hours/day | Bidirectional streaming
          "gemini-2.5-flash-preview-tts" # 1M chars/month | Text-to-speech specialization

          # Legacy/Compatibility (Retirement pending mid-2026)
          "gemini-2.0-flash-001" # 1M Context | Legacy stable
          "gemini-2.0-flash-lite-001" # 1M Context | Legacy cost-optimized
        ];

        pkgs = import inputs.nixpkgs { inherit system; };
        inherit (pkgs) lib;

        modelPackages = lib.genAttrs models (
          name:
          pkgs.stdenv.mkDerivation {
            inherit name;
            dontUnpack = true;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            installPhase = ''
              mkdir -p $out/bin
              makeWrapper ${lib.getExe pkgs.gemini-cli} $out/bin/gemini \
                --set GEMINI_MODEL ${name} \
                --set GEMINI_SYSTEM_MD ${./README.md}
            '';
          }
        );

        modelShells = lib.mapAttrs (
          name: pkg:
          pkgs.mkShell {
            packages = [ pkg ];
            shellHook = ''echo "using ${pkg.name}"'';
          }
        ) modelPackages;

      in
      rec {

        packages = modelPackages // {
          default = modelPackages.gemini-3-flash-preview;
        };

        devShells = modelShells // {
          default = modelShells.${packages.default.name};
        };

      }
    );
}
