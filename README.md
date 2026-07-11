# Kernel Drivers

Playground for Linux kernel driver development for fun.

## Development

```sh
nix develop
```

## VM

### Pool

```sh
just vm pool define
just vm pool start
```

### Domain

```sh
just vm init deb13
just vm start deb13
just vm sh deb13
```

## clangd

```sh
bear --append --output compile_commands.json -- \
  make -C "$K_DIR" M="$PWD/labs/hello" HOSTCC=cc modules
```
