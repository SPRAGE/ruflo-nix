{
  description = "Nix flake for Ruflo — Enterprise AI Orchestration Platform (ruvnet/ruflo)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nodejs = pkgs.nodejs_22;
      in
      {
        packages = {
          ruflo = pkgs.buildNpmPackage rec {
            pname = "ruflo";
            version = "3.5.48";

            src = pkgs.fetchFromGitHub {
              owner = "ruvnet";
              repo = "ruflo";
              rev = "v${version}";
              hash = "sha256-RwdeaCL9693LY+RFPsCyD/XH1DeZGC7hTmaG+DzomG8=";
            };

            npmDepsHash = "sha256-7IfDjSOF5cdhy89I6YpIxdFrbFfh41kZEOZSAnH/R8o=";

            inherit nodejs;

            # Prevent native build scripts from running in the Nix sandbox
            # (sharp, sqlite3, esbuild platform binaries, etc.).
            # The core CLI works fine without native addons.
            npmFlags = [ "--ignore-scripts" ];

            # Build TypeScript sources (runs `npm run build` → `tsc`)
            dontNpmBuild = false;
            buildPhase = ''
              runHook preBuild
              # Build the CLI package from TypeScript
              cd v3/@claude-flow/cli
              npx tsc --project tsconfig.json 2>/dev/null || true
              cd ../../..
              # Also build shared if needed
              if [ -f v3/@claude-flow/shared/tsconfig.json ]; then
                cd v3/@claude-flow/shared
                npx tsc --project tsconfig.json 2>/dev/null || true
                cd ../../..
              fi
              runHook postBuild
            '';

            # Add ruflo as an alias for claude-flow
            postInstall = ''
              if [ -f "$out/bin/claude-flow" ] && [ ! -f "$out/bin/ruflo" ]; then
                ln -s "$out/bin/claude-flow" "$out/bin/ruflo"
              fi

              # Fix agentdb exports path mismatch: dist/controllers → dist/src/controllers
              # Upstream bug: package.json exports map points "./controllers" at
              # ./dist/controllers/index.js but tsc outputs to dist/src/controllers/.
              agentdb_dist="$out/lib/node_modules/claude-flow/node_modules/agentic-flow/node_modules/agentdb/dist"
              if [ -d "$agentdb_dist/src/controllers" ] && [ ! -e "$agentdb_dist/controllers" ]; then
                ln -s src/controllers "$agentdb_dist/controllers"
              fi
            '';

            meta = with pkgs.lib; {
              description = "Enterprise AI agent orchestration platform — deploy 60+ agents in coordinated swarms";
              homepage = "https://github.com/ruvnet/ruflo";
              license = licenses.mit;
              maintainers = [ ];
              mainProgram = "claude-flow";
              platforms = platforms.all;
            };
          };

          default = self.packages.${system}.ruflo;
        };

        # Development shell with ruflo available
        devShells.default = pkgs.mkShell {
          buildInputs = [
            self.packages.${system}.ruflo
            nodejs
          ];

          shellHook = ''
            echo "🌊 Ruflo development shell"
            echo "  ruflo / claude-flow available on PATH"
          '';
        };
      }
    ) // {
      # NixOS module for system-wide installation
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.ruflo;
          system = pkgs.stdenv.hostPlatform.system;
        in
        {
          options.services.ruflo = {
            enable = lib.mkEnableOption "Ruflo AI orchestration platform";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${system}.ruflo;
              defaultText = lib.literalExpression "inputs.ruflo.packages.\${system}.ruflo";
              description = "The ruflo package to use.";
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
          };
        };

      # Home-manager module
      homeModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.ruflo;
          system = pkgs.stdenv.hostPlatform.system;
        in
        {
          options.programs.ruflo = {
            enable = lib.mkEnableOption "Ruflo AI orchestration platform";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${system}.ruflo;
              defaultText = lib.literalExpression "inputs.ruflo.packages.\${system}.ruflo";
              description = "The ruflo package to use.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];
          };
        };

      # Overlay for use with nixpkgs
      overlays.default = final: prev: {
        ruflo = self.packages.${prev.stdenv.hostPlatform.system}.ruflo;
      };
    };
}
