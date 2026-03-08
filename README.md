# ruflo-nix

Nix flake wrapping [ruvnet/ruflo](https://github.com/ruvnet/ruflo) — the Enterprise AI Orchestration Platform for Claude Code.

## Quick start

### Try it without installing

```bash
nix run github:shaun/ruflo-nix -- --help
```

### Use in a dev shell

```bash
nix shell github:shaun/ruflo-nix
ruflo --version
```

### Install in a flake-based NixOS/home-manager config

Add the input:

```nix
# flake.nix
{
  inputs.ruflo.url = "github:shaun/ruflo-nix";
  # ...
}
```

#### NixOS (system-wide)

```nix
# configuration.nix
{ inputs, ... }:
{
  imports = [ inputs.ruflo.nixosModules.default ];
  services.ruflo.enable = true;
}
```

#### home-manager (per-user)

```nix
# home.nix
{ inputs, ... }:
{
  imports = [ inputs.ruflo.homeModules.default ];
  programs.ruflo.enable = true;
}
```

#### Overlay

```nix
{
  nixpkgs.overlays = [ inputs.ruflo.overlays.default ];
  # Then use pkgs.ruflo anywhere
}
```

#### As a standalone package

```nix
environment.systemPackages = [
  inputs.ruflo.packages.${pkgs.system}.ruflo
];
```

## Provided binaries

| Binary        | Description                                  |
|---------------|----------------------------------------------|
| `claude-flow` | Primary CLI (name from upstream package.json) |
| `ruflo`       | Alias → `claude-flow`                        |

## Auto-updates

A GitHub Actions workflow runs daily at 06:00 UTC and checks for new upstream releases. When a new version is found, it:

1. Updates the version, source hash, and npm dependency hash in `flake.nix`
2. Verifies the build succeeds
3. Opens a pull request for review

You can also trigger the update manually from the Actions tab.

## Building locally

```bash
git clone https://github.com/shaun/ruflo-nix
cd ruflo-nix
nix build
./result/bin/ruflo --version
```

## License

This Nix wrapper is provided under the MIT license, same as the upstream ruflo project.
