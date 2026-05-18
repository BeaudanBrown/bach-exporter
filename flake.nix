{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgsUnstable,
      flake-utils,
      pre-commit-hooks,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgsUnstable = nixpkgsUnstable.legacyPackages.${system};
        bachR = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            bslib
            crew
            dotenv
            future
            ggplot2
            jsonlite
            languageserver
            qs2
            redcapAPI
            remotes
            renv
            shiny
            shinyFiles
            targets
            tarchetypes
            testthat
          ];
        };
        bachExporter = pkgs.writeShellApplication {
          name = "bach-exporter";
          runtimeInputs = [ bachR ];
          text = ''
            exec Rscript - "$@" <<'RSCRIPT'
            args <- commandArgs(trailingOnly = TRUE)
            shared_root <- if (length(args) > 0L && nzchar(args[[1L]])) args[[1L]] else NULL
            source("${self}/launch_bach_exporter.R", chdir = TRUE)
            launch_bach_exporter(shared_root)
            RSCRIPT
          '';
        };
      in
      {
        packages = {
          default = bachExporter;
          bach-exporter = bachExporter;
        };
        apps = {
          default = {
            type = "app";
            program = "${bachExporter}/bin/bach-exporter";
          };
          bach-exporter = {
            type = "app";
            program = "${bachExporter}/bin/bach-exporter";
          };
        };
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              air-fmt = {
                enable = true;
                entry = "${pkgs.air-formatter}/bin/air format";
                files = ".*\.[rR]$";
              };
            };
          };
        };
        devShells.default = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          env.R_LIBS_USER = "./.Rlib";
          env.PRE_COMMIT_HOME = "./.pre-commit-cache";
          env.PKG_CONFIG_PATH = pkgs.lib.makeSearchPath "lib/pkgconfig" [
            pkgs.libsodium.dev
            pkgs.mbedtls
            pkgs.openssl.dev
            pkgs.zlib.dev
            pkgs.curl.dev
            pkgs.libxml2.dev
            pkgs.fontconfig.dev
            pkgs.freetype.dev
            pkgs.harfbuzz.dev
            pkgs.fribidi.dev
            pkgs.libpng.dev
            pkgs.libtiff.dev
            pkgs.libjpeg.dev
          ];
          buildInputs = [
            pkgs.bashInteractive
            self.checks.${system}.pre-commit-check.enabledPackages
          ];
          packages =
            with pkgs;
            [
              R
              cmake
              curl
              fontconfig
              freetype
              fribidi
              gcc
              gnumake
              harfbuzz
              libjpeg
              libpng
              libsodium
              libtiff
              libxml2
              mbedtls
              openssl
              pkg-config
              quarto
              xz
              zlib
            ]
            ++ (with pkgsUnstable; [
              air-formatter
            ])
            ++ (with rPackages; [
              ggplot2
              shiny
              shinyFiles
              bslib
              targets
              tarchetypes
              crew
              future
              qs2
              languageserver
              dotenv
              jsonlite
              renv
              remotes
              redcapAPI
              testthat
            ]);
        };
      }
    );
}
