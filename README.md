# Lookout Flake

Standalone Nix flake packaging the Lookout desktop app from
[`hackclub/lookout`](https://github.com/hackclub/lookout).

## Install

In a NixOS flake:

```nix
{
  inputs.lookout-flake.url = "github:elijah629/lookout-flake";

  outputs =
    { nixpkgs, lookout-flake, ... }:
    {
      nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            environment.systemPackages = [
              lookout-flake.packages.x86_64-linux.default
            ];
          }
        ];
      };
    };
}
```

Or install via the overlay:

```nix
{
  nixpkgs.overlays = [ inputs.lookout-flake.overlays.default ];
  environment.systemPackages = [ pkgs.lookout ];
}
```

## Update

Refresh the pinned Lookout source and dependency hashes with:

```sh
nix run .#update-lookout
```

The GitHub workflow in `.github/workflows/update.yml` runs the same update and
opens a PR when anything changes.
