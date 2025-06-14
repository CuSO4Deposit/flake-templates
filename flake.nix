{
  description = "My flake templates";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        templates.default = self.templates.uv-impure;
        templates = {
          uv-impure = {
            description = "A flake that creates a uv venv";
            path = ./templates/uv-impure;
            welcomeText = ''
              # uv impure
              ## Intended Usage
              Use `uv` command to initialize and manipulate the project.

              This flake creates hidden files. Use `ls -a` to check them.

              The venv is automatically created and activated when entering 
              the dev shell.  It is recommended to use direnv to enter the dev
              shell, the corresponding `.envrc` is also provided.
            '';
          };
        };
      };
      imports = [
        inputs.pre-commit-hooks.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          pre-commit.settings = {
            src = ./.;
            hooks = {
              markdownlint.enable = true;
              nixfmt-rfc-style.enable = true;
            };
          };
          devShells = {
            default = pkgs.mkShellNoCC {
              shellHook = ''
                # install pre-commit hooks
                ${config.pre-commit.installationScript}
              '';
            };
          };
        };
    };
}
