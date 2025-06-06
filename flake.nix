{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      systems = import inputs.systems;
      perSystem =
        {
          config,
          lib,
          pkgs,
          system,
          ...
        }:
        let
          inputFile = "./src/main.typ";
          outputFile = "./src/main.pdf";
          fonts = with pkgs; [
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif
            ipafont
          ];
          font-paths = builtins.concatStringsSep ":" fonts;
          typst-compile = pkgs.writeShellScriptBin "compile" ''
            export TYPST_FONT_PATHS=${font-paths}
            ${pkgs.typst}/bin/typst compile \
              --ignore-system-fonts \
              ${inputFile} \
              ${outputFile}
          '';
          typst-fonts = pkgs.writeShellScriptBin "fonts" ''
            export TYPST_FONT_PATHS=${font-paths}
            ${pkgs.typst}/bin/typst fonts \
              --ignore-system-fonts \
          '';
        in
        {
          # _module.args.pkgs = import self.inputs.nixpkgs {
          #   inherit system;
          #   config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          #   ];
          # };

          treefmt = {
            flakeCheck = true;
            flakeFormatter = true;
            programs = {
              nixfmt.enable = true;
              typstyle.enable = true;
            };
          };

          apps = {
            "compile" = {
              type = "app";
              meta.description = "Compile Typst files to PDF";
              program = typst-compile;
            };
            "fonts" = {
              type = "app";
              meta.description = "List available Typst fonts";
              program = typst-fonts;
            };

          };

          devShells = {
            default = pkgs.mkShell {
              packages =
                with pkgs;
                [
                  typst
                  # corefonts
                  ipafont
                ]
                ++ [
                  typst-compile
                  typst-fonts
                ];
              shellHook = ''
                export TYPST_FONT_PATHS=${font-paths}
              '';
            };
          };
        };
    };
}
