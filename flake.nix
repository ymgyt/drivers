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
      llvm = pkgs.llvmPackages;

      repoPackages = with pkgs; [
        just
        nushell
      ];

      vmPackages = with pkgs; [
        curl
        gettext
        libvirt
        qemu_kvm
      ];

      kernelPackages = with pkgs; [
        bc
        bison
        elfutils
        flex
        gnumake
        kmod
        ncurses
        openssl
        perl
        pkg-config
        python3
        xz
        zlib
      ];

      toolchainPackages = [
        llvm.clang
        llvm.clang-tools
        llvm.lld
        llvm.llvm
        llvm.libclang
        pkgs.gdb
        pkgs.rustc
        pkgs.rust-bindgen-unwrapped
      ];
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = repoPackages ++ vmPackages ++ kernelPackages ++ toolchainPackages;
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
          pkgs.ncurses
          pkgs.elfutils
          pkgs.zlib
          pkgs.openssl
        ];
        LIBCLANG_PATH = "${llvm.libclang.lib}/lib";
        RUSTC = "${pkgs.rustc}/bin/rustc";
        RUST_LIB_SRC = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

        shellHook = ''
          export CC="${llvm.clang-unwrapped}/bin/clang"
          export HOSTCC="${llvm.clang}/bin/clang"
          export HOSTCXX="${llvm.clang}/bin/clang++"
          export BINDGEN="${pkgs.rust-bindgen-unwrapped}/bin/bindgen"
          export KERNEL_MAKE_ARGS="LLVM=1 CC=$CC HOSTCC=$HOSTCC HOSTCXX=$HOSTCXX RUSTC=$RUSTC BINDGEN=$BINDGEN"
          exec nu
        '';
      };
    };
}
