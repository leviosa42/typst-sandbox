{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs@{ self, flake-parts, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import inputs.systems;
    perSystem = { config, lib, pkgs, system, ... }:
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

      apps = {
        "compile" = {
          type = "app";
          program = typst-compile;
        };
        "fonts" = {
          type = "app";
          program = typst-fonts;
        };

      };

      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            typst
            # corefonts
            ipafont
          ]
          ++ fonts
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
