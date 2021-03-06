{
  description = "Collections beyond Record and Variant that make use of row polymorphism";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rnix-lsp = {
      url = "github:nix-community/rnix-lsp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    easy-purescript-nix-source = {
      url = "github:justinwoo/easy-purescript-nix";
      flake = false;
    };
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , easy-purescript-nix-source
    , gitignore
    , nixpkgs
    , pre-commit-hooks
    , rnix-lsp
    , flake-utils
    }:
    (flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs { inherit system; };

        easy-ps = import easy-purescript-nix-source { inherit pkgs; };

        spagoPkgs = import ./spago-packages.nix { inherit pkgs; };

        inherit (gitignore.lib) gitignoreSource;

        inherit (easy-ps) psa purescript-language-server purs purs-tidy spago spago2nix;

        inherit (pkgs) fd;

        inherit (pkgs.nodePackages) prettier;

        getGlob = { name, version, ... }: ''".spago/${name}/${version}/src/**/*.purs"'';

        spagoSources =
          builtins.toString
            (builtins.map getGlob (builtins.attrValues spagoPkgs.inputs));

        src = gitignoreSource ./.;

        purs-tidy-hook = {
          enable = true;
          name = "purs-tidy";
          entry = "${purs-tidy}/bin/purs-tidy format-in-place";
          files = "\\.purs$";
          language = "system";
        };

        prettier-hook = {
          enable = true;
          types_or = [ "javascript" "css" "html" ];
        };

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          inherit src;
          hooks = {
            nixpkgs-fmt = {
              enable = true;
              excludes = [ ".*spago-packages.nix$" ];
            };
            inherit purs-tidy-hook;
            prettier = prettier-hook;
          };
        };

        heterogeneous-collections =
          pkgs.stdenv.mkDerivation {
            name = "heterogeneous-collections";
            buildInputs = [
              spagoPkgs.installSpagoStyle
            ];
            nativeBuildInputs = [
              psa
              purs
              spago
            ];
            inherit src;
            unpackPhase = ''
              cp $src/spago.dhall .
              cp $src/packages.dhall .
              cp -r $src/src .
              install-spago-style
            '';
            buildPhase = ''
              set -e
              echo building project...
              psa compile --strict --censor-lib ${spagoSources} './src/**/*.purs'
              echo done.
            '';
            installPhase = ''
              mkdir $out
              mv output $out/
            '';
          };

        clean = pkgs.writeShellScriptBin "clean" ''
          echo cleaning project...
          rm -rf .spago .spago2nix output
          echo removed .spago
          echo removed .spago2nix
          echo removed output
          echo done.
        '';

        fix-purs-tidy = pkgs.writeShellScriptBin "fix-purs-tidy" ''
          set -e
          echo formatting PureScript files...
          ${fd}/bin/fd \
            --extension purs \
            --exec-batch ${purs-tidy}/bin/purs-tidy format-in-place {}
          echo done.
        '';

        fix-prettier = pkgs.writeShellScriptBin "fix-prettier" ''
          set -e
          echo formatting JavaScript, CSS, and HTML files...
          ${fd}/bin/fd \
            --extension js \
            --extension ts \
            --extension css \
            --extension html \
            --exec-batch ${prettier}/bin/prettier -w format-in-place {}
          echo done.
        '';

      in
      {
        packages = {
          inherit heterogeneous-collections purs-tidy-hook fix-purs-tidy prettier-hook fix-prettier;
        };
        hydraJobs = {
          inherit heterogeneous-collections pre-commit-check;
        };
        defaultPackage = heterogeneous-collections;
        devShell = pkgs.mkShell {
          buildInputs = [
            clean
            fix-purs-tidy
            fix-prettier
            psa
            purescript-language-server
            purs
            purs-tidy
            rnix-lsp.defaultPackage."${system}"
            spago
            spago2nix
            prettier
          ];
          inherit (pre-commit-check) shellHook;
        };
      }
      )
    );
}
