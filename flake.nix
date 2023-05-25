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
      name = "OpenProject";
      gems = ruby-nix.lib pkgs {
        inherit name;
        gemset = nix/gemset.nix;
        ruby = pkgs.ruby_3_2;
      };
      version = "12.5.4";
    in
    {
      packages.backend = pkgs.stdenvNoCC.mkDerivation {
        pname = "${name}-Backend";
        inherit version;

        buildInputs = [
          gems.env
        ];

        src = ./.;

        patches = [
          nix/rake_no_spring.patch
        ];

        installPhase = ''
          mkdir $out
          cp -r app bin config db extra lib lib_static modules spec $out
          cp Gemfile Gemfile.lock Gemfile.modules config.ru Rakefile $out
        '';
          #cp -r * $out
      };
      packages.frontend = pkgs.buildNpmPackage {
        pname = "${name}-Frontend";
        inherit version;

        srcs = [
          ./frontend
          ./modules
        ];
        sourceRoot = "frontend";

        nativeBuildInputs = [
          pkgs.python3
          pkgs.nodejs
        ];

        preBuild = ''
          mkdir -p ../public/assets/
          cp src/app/features/plugins/linked-plugins.module.ts.example src/app/features/plugins/linked-plugins.module.ts
          cp src/app/features/plugins/linked-plugins.styles.sass.example src/app/features/plugins/linked-plugins.styles.sass
        '';

        postInstall = ''
          cp -r ../public $out/
        '';

        #dontNpmBuild = true;

        npmDepsHash = "sha256-cGrgMwhh/WfahMd8TbzHZ6PruU+4V7cogWJp8gMCIlI=";

      };
    
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          gems.env
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
