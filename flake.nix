{
  description = "OpenProject";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    flake-utils.url = github:numtide/flake-utils;
    ruby-nix.url = github:sagittaros/ruby-nix;
  };

  outputs = { self, nixpkgs, flake-utils, ruby-nix }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      gems = ruby-nix.lib pkgs {
        name = "OpenProject";
        gemset = nix/gemset.nix;
        ruby = pkgs.ruby_3_2;
      };
      version = "12.5.4";
    in
    {
      packages.default = pkgs.stdenvNoCC.mkDerivation {
        pname = "OpenProject";
        inherit version;

        buildInputs = [
          gems.ruby
          gems.env
        ];

        src = ./.;

        #postFixup = ''
        #  patchShebangs bin/
        #'';

        installPhase = ''
          mkdir $out
          cp -r bin config db extra lib lib_static modules spec $out
          cp Gemfile Gemfile.lock Gemfile.modules config.ru $out
        '';
      };
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          gems.env
          gems.ruby
        ];
      };
      devShells.bundix = pkgs.mkShell {
        packages = with pkgs; [
          bundix
        ];
      };
    }
  );
}
