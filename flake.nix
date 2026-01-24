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
      kDir = "/nix/store/13aigh240fpwqws8dynryi14vfhjqsah-linux-6.18.2-dev/lib/modules/6.18.2/build";

      llvm = pkgs.llvmPackages_20;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          llvm.clang-tools
          llvm.clang-unwrapped
          llvm.lld
          llvm.llvm

          # bindgen用
          llvm.libclang
          # header内のincludeを解決
          # 厳密にはkDirを参照する必要があるように思われる
          linuxHeaders

          stdenv.cc

          b4
          bc
          elfutils
          flex
          bison
          bear
        ];
        K_DIR = kDir;

        # bindgen用
        LIBCLANG_PATH = "${llvm.libclang.lib}/lib";
        BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.linuxHeaders}/include";

        shellHook = ''
          exec nu
        '';
      };
    };
}
