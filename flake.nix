{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell.url = "github:numtide/devshell";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [inputs.devshell.flakeModule];
      systems = ["x86_64-darwin"];
      perSystem = {
        config,
        pkgs,
        ...
      }: {
        packages.default = pkgs.rustPlatform.buildRustPackage rec {
          pname = "win95-maze-rs";
          version = "unstable";
          src = inputs.gitignore.lib.gitignoreSource ./.;
          # cargoHash = "sha256-jtBw4ahSl88L0iuCXxQgZVm1EcboWRJMNtjxLVTtzts=";
          nativeBuildInputs = with pkgs; [cmake];
          buildInputs = with pkgs; [
            darwin.apple_sdk.frameworks.Carbon
            darwin.apple_sdk.frameworks.AppKit
            darwin.apple_sdk.frameworks.Foundation
            glfw
            lldb
          ];
          cargoLock = {
            lockFile = ./Cargo.lock;
          };
        };

        devshells.default = {
          name = "win95-maze-rs-env";
          env = [];
          packages = with pkgs; [
            cargo
            cmake
            glfw
            rust-analyzer
            rustc
          ];
        };
      };
    };
}
