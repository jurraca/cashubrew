{
  description = "An Elixir development shell.";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-24.05;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }:
    # Build for each default system of flake-utils: ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"].
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        beamPackages = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang_27;
        opts =
         with pkgs; lib.optional stdenv.isLinux inotify-tools ++
          lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
            CoreServices
            Foundation
          ]);

        buildInputs =
          let
            inherit beamPackages;
            elixir = beamPackages.elixir_1_16;
            hex = beamPackages.hex;
            mix2nix = pkgs.mix2nix;
          in
          [
            elixir
            hex
            mix2nix
	    pkgs.postgresql
          ] ++ opts;

        shellHook = ''
          # Set up `mix` to save dependencies to the local directory
          mkdir -p .nix-mix
          mkdir -p .nix-hex
          export MIX_HOME=$PWD/.nix-mix
          export HEX_HOME=$PWD/.nix-hex
          export PATH=$MIX_HOME/bin:$PATH
          export PATH=$HEX_HOME/bin:$PATH

          # BEAM-specific
          export LANG=en_US.UTF-8
          export ERL_AFLAGS="-kernel shell_history enabled"
    # postgres related
    # keep all your db data in a folder inside the project
    export PGDATA="$PWD/db"

    # phoenix related env vars
    export POOL_SIZE=15
    export DB_URL="postgresql://postgres:postgres@localhost:5432/cashubrew_dev"
    export PORT=4000
        '';
      in
      # output attributes
      {
        devShells.default = pkgs.mkShell {
          inherit
            buildInputs
            shellHook;
        };
      }
    );
}

