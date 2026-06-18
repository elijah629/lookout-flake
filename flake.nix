{
  description = "Nix flake packaging the Lookout desktop app from latest source";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lookout-src = {
      url = "github:hackclub/lookout";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      lookout-src,
    }:
    let
      inherit (nixpkgs) lib;
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs supportedSystems;
      mkPkgs = system: import nixpkgs { inherit system; };
      mkLookout =
        system:
        (mkPkgs system).callPackage ./package.nix {
          src = lookout-src;
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          lookout = mkLookout system;
        in
        {
          default = lookout;
          inherit lookout;
          lookout-npm-deps = lookout.npmDeps;
          lookout-cargo-deps = lookout.cargoDeps;
        }
      );

      checks = forAllSystems (system: {
        default = self.packages.${system}.default;
        lookout = self.packages.${system}.lookout;
      });

      apps = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;

          updateLookout = pkgs.writeShellApplication {
            name = "update-lookout";

            runtimeInputs = [
              pkgs.coreutils
              pkgs.gnused
              pkgs.nix
              pkgs.perl
            ];

            text = ''
              exec bash ./scripts/update.sh
            '';
          };
        in
        {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/lookout";
            meta.description = "Run the Lookout desktop app";
          };

          lookout = {
            type = "app";
            program = "${self.packages.${system}.lookout}/bin/lookout";
            meta.description = "Run the Lookout desktop app";
          };

          update-lookout = {
            type = "app";
            program = "${updateLookout}/bin/update-lookout";
            meta.description = "Refresh the pinned Lookout source and dependency hashes";
          };
        }
      );

      overlays.default =
        final: prev:
        let
          system = prev.stdenv.hostPlatform.system;
        in
        lib.optionalAttrs (builtins.hasAttr system self.packages) {
          lookout = self.packages.${system}.default;
        };
    };
}
