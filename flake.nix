{
  description = "Out-of-tree Linux drivers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      # how to set this value properly?
      kDir = "/nix/store/nx4mdfzx7rkwl9zkqspmfcxxznd92akj-linux-6.12.63-dev/lib/modules/6.12.63/build";
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        K_DIR = kDir;

        shellHook = ''
          exec nu
        '';
      };
    };
}
