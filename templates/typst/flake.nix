{
  description = "A Typst project with pre-commit-hooks and basic CJK support.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Example of downloading icons from a non-flake source
    # font-awesome = {
    #   url = "github:FortAwesome/Font-Awesome";
    #   flake = false;
    # };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      typix,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;

        typixLib = typix.lib.${system};

        src = typixLib.cleanTypstSource ./.;
        commonArgs = {
          typstSource = "main.typ";

          fontPaths = [
            # Add paths to fonts here
            "${pkgs.source-han-sans}/share/fonts/opentype"
            "${pkgs.source-han-serif}/share/fonts/opentype"
          ];

          virtualPaths = [
            # Add paths that must be locally accessible to typst here
            # {
            #   dest = "icons";
            #   src = "${inputs.font-awesome}/svgs/regular";
            # }
          ];
        };

        # Compile a Typst project, *without* copying the result
        # to the current directory
        build-drv = typixLib.buildTypstProject (
          commonArgs
          // {
            inherit src;
          }
        );

        # Compile a Typst project, and then copy the result
        # to the current directory
        build-script = typixLib.buildTypstProjectLocal (
          commonArgs
          // {
            inherit src;
          }
        );

        # Watch a project and recompile on changes
        watch-script = typixLib.watchTypstProject commonArgs;
      in
      {
        checks = {
          inherit
            build-drv
            build-script
            watch-script
            inputs
            ;
          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              markdownlint.enable = true;
              nixfmt-rfc-style.enable = true;
              typstyle.enable = true;
            };
          };
        };

        packages.default = build-drv;

        apps = rec {
          default = watch;
          build = flake-utils.lib.mkApp {
            drv = build-script;
          };
          watch = flake-utils.lib.mkApp {
            drv = watch-script;
          };
        };

        devShells.default = typixLib.devShell {
          inherit (commonArgs) fontPaths virtualPaths;
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
          packages = [
            # WARNING: Don't run `typst-build` directly, instead use `nix run .#build`
            # See https://github.com/loqusion/typix/issues/2
            # build-script
            watch-script
            # More packages can be added here, like typstfmt
            # pkgs.typstfmt
          ];
        };
      }
    );
}
