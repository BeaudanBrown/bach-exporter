{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
        bachRuntimePackages = with pkgs.rPackages; [
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
        bachExporterPackage = pkgs.rPackages.buildRPackage {
          name = "bachExporter-0.0.1";
          src = self;
          propagatedBuildInputs = bachRuntimePackages;
          dontCheck = true;
        };
        bachR = pkgs.rWrapper.override {
          packages = bachRuntimePackages ++ [ bachExporterPackage ];
        };
        bachExporter = pkgs.writeShellApplication {
          name = "bach-exporter";
          runtimeInputs = [ bachR ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.xdg-utils ];
          text = ''
            exec Rscript - "$@" <<'RSCRIPT'
            args <- commandArgs(trailingOnly = TRUE)
            shared_root <- if (length(args) > 0L && nzchar(args[[1L]])) args[[1L]] else NULL
            open_browser <- function(url) {
              message("BACH Exporter is running at: ", url)
              opened <- FALSE
              try_open <- function(command, command_args) {
                if (!nzchar(Sys.which(command))) {
                  return(FALSE)
                }
                status <- tryCatch(
                  system2(command, command_args, wait = FALSE),
                  error = function(err) 1L
                )
                identical(status, 0L)
              }
              if (identical(Sys.info()[["sysname"]], "Darwin")) {
                opened <- try_open("open", url)
              } else if (nzchar(Sys.getenv("WSL_DISTRO_NAME", unset = ""))) {
                opened <- try_open("wslview", url) ||
                  try_open("cmd.exe", c("/c", "start", "", url))
              } else if (.Platform$OS.type == "windows") {
                opened <- tryCatch({ utils::browseURL(url); TRUE }, error = function(err) FALSE)
              } else {
                opened <- try_open("xdg-open", url)
              }
              if (!isTRUE(opened)) {
                message("Open the URL above in your browser.")
              }
              invisible(opened)
            }
            shiny::runApp(
              bachExporter::run_app(shared_root),
              launch.browser = open_browser
            )
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
