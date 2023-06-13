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
        name = "${name}-Gems";
        gemset = nix/gemset.nix;
        ruby = pkgs.ruby_3_2;
      };
      version = "12.5.4";
      inherit (pkgs) postgresql;

      openproject = pkgs.buildNpmPackage {
        pname = name;
        inherit version;

        nativeBuildInputs = [
          gems.env
          pkgs.python3
        ];

        src = self;
        sourceRoot = "source/frontend";

        prePatch = ''
          cd ..
          chmod u+w bin
          chmod u+w lib/tasks
        '';

        postPatch = ''
          cd frontend
        '';

        #patch -p1 < nix/rake_no_spring.patch
        #patch lib/tasks/assets.rake nix/assets_no_npm.patch
        patches = [
          nix/rake_no_spring.patch
          nix/assets_no_npm.patch
        ];

        npmDepsHash = "sha256-cGrgMwhh/WfahMd8TbzHZ6PruU+4V7cogWJp8gMCIlI=";

        preBuild = ''
          cd ..
          patchShebangs --build bin
          mkdir ../nulldb
          mkdir ../pgsock
          pwd
          ls
          chmod u+w log/ tmp/ public/ config/
          ${postgresql}/bin/initdb -D ../nulldb --auth=trust
          ${postgresql}/bin/pg_ctl -D ../nulldb -l ../pglog -o '-c listen_addresses="" -c unix_socket_directories=$PWD/../pgsock' -w start
          ${postgresql}/bin/createdb -h /build/pgsock assets
          ${postgresql}/bin/createuser -h /build/pgsock postgres
          SECRET_KEY_BASE=dfg876adfhg9768ah DATABASE_URL=postgres:///assets?host=/build/pgsock RAILS_ENV=production bin/rake db:migrate assets:precompile
          ${postgresql}/bin/pg_ctl -D ../nulldb stop
          cd frontend
        '';

        postBuild = ''
          cd ..
          SECRET_KEY_BASE=dfg876adfhg9768ah DATABASE_URL=postgres:///assets?host=/build/pgsock RAILS_ENV=production bin/rake assets:rebuild_manifest
          cd frontend
        '';
        #${postgresql}/bin/psql -h /build/pgsock -U postgres -c "grant all privileges on database assets to postgres;"

        installPhase = ''
          cd ..
          mkdir $out
          cp -r app bin config db extra lib lib_static modules spec $out
          cp Gemfile Gemfile.lock Gemfile.modules config.ru Rakefile $out
          cp -r public $out
        '';
          #cp -r * $out
      };
    in {
      packages = {
        inherit openproject;
        default = openproject;
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
      devShells.postgres = pkgs.mkShell {
        packages = with pkgs; [
          postgresql
        ];
      };
    }
  );
}
