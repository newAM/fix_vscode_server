{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    src = builtins.path {
      path = ./.;
      name = "fix_vscode_server_source";
    };

    pyproject = nixpkgs.lib.importTOML ./pyproject.toml;
    pname = pyproject.tool.poetry.name;

    python3Overlay = final: prev: pfinal: pprev:
      pprev.buildPythonPackage {
        inherit pname src;
        inherit (pyproject.tool.poetry) version;
        format = "pyproject";

        nativeBuildInputs = [
          pprev.poetry-core
        ];

        pythonImportsCheck = [
          pname
        ];

        postInstall = let
          rpath = with prev;
          # https://github.com/msteen/nixos-vscode-server/blob/cb48580bb58d28e6fbf0f5f032f57727dff3bb9c/pkgs/auto-fix-vscode-server.nix#L16
            lib.makeLibraryPath [
              stdenv.cc.cc.lib

              # dotnet
              curl
              icu
              libunwind
              libuuid
              lttng-ust
              openssl
              zlib

              # mono
              krb5
            ];
        in ''
          wrapProgram $out/bin/fix_vscode_server \
            --add-flags "--patchelf ${prev.patchelf}/bin/patchelf" \
            --add-flags "--interpreter $(cat $NIX_CC/nix-support/dynamic-linker)" \
            --add-flags "--rpath ${rpath}" \
            --add-flags "--vscode ${prev.vscode}"

          ln -s $out/bin/fix_vscode_server $out/bin/fix-vscode-server
        '';

        meta = with nixpkgs.lib; {
          inherit (pyproject.tool.poetry) description;
          homepage = pyproject.tool.poetry.repository;
          license = with licenses; [mit];
        };
      };

    overlay = final: prev: rec {
      python3 = prev.python3.override {
        packageOverrides = pfinal: pprev: {
          fix_vscode_server = python3Overlay final prev pfinal pprev;
        };
      };
      python3Packages = python3.pkgs;
    };

    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [overlay];
      config.allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [
          "vscode"
        ];
    };
  in {
    overlays = {
      default = overlay;
      python3 = python3Overlay;
    };

    packages.x86_64-linux.default = pkgs.python3Packages.fix_vscode_server;

    apps.x86_64-linux.
      default = {
      type = "app";
      program = "${pkgs.python3Packages.fix_vscode_server}/bin/fix_vscode_server";
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    checks.x86_64-linux = let
      nixSrc = nixpkgs.lib.sources.sourceFilesBySuffices src [".nix"];
      pySrc = nixpkgs.lib.sources.sourceFilesBySuffices src [".py" ".toml"];
    in {
      pkg = self.packages.x86_64-linux.default;

      alejandra = pkgs.runCommand "alejandra" {} ''
        ${pkgs.alejandra}/bin/alejandra --check ${nixSrc}
        touch $out
      '';

      statix = pkgs.runCommand "statix" {} ''
        ${pkgs.statix}/bin/statix check ${nixSrc}
        touch $out
      '';

      flake8 =
        pkgs.runCommand "flake8"
        {
          buildInputs = with pkgs.python3Packages; [
            flake8
            flake8-bugbear
            pep8-naming
          ];
        }
        ''
          flake8 --max-line-length 88 ${pySrc}
          touch $out
        '';

      black = pkgs.runCommand "black" {} ''
        ${pkgs.python3Packages.black}/bin/black ${pySrc}
        touch $out
      '';
    };
  };
}
