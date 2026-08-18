# Kernel Drivers

Playground for Linux kernel driver development for fun.

## Development

The Linux source tree is expected at `../linux`.

```sh
nix develop
just
```

## VM

`deb13` boots the Debian kernel and is used to bootstrap the kernel configuration.
`rust` boots the host-built kernel with a Debian root filesystem.

The host directory `vm/shared` is exposed to both guests through virtiofs with the mount tag `drivers`.

## Workflow

### Kernel

Build the rust-next kernel from the tracked Debian seed config:

```sh
just kernel initconfig      # seed .config from dev/kernel/config/debian-13-amd64
just kernel olddefconfig    # resolve it against the current rust-next Kconfig
just kernel rustconfig      # enable RUST (and GENDWARFKSYMS)
just kernel vmconfig        # build in the drivers required to boot the VM
just kernel localmodconfig vm/shared/lsmod-<release>  # optional: prune modules using an lsmod snapshot from deb13
just kernel image           # arch/x86/boot/bzImage
just kernel modules         # in-tree modules and Module.symvers
```

After updating `../linux`, rerun `olddefconfig`, `image`, and `modules`.

### VM

```sh
just vm pool define   # once
just vm pool start    # once per host boot
just vm init rust
just vm boot rust     # direct kernel boot of the built bzImage; detach with Ctrl+]
just vm console rust  # attach to a running VM
```

### Module

```sh
cd handson/miscdrv/module
make modules
cp miscdrv.ko ../../../vm/shared/
```

Inside the VM:

```sh
mount -t virtiofs drivers /mnt/drivers
insmod /mnt/drivers/miscdrv.ko
rmmod miscdrv
```

### Seed config

To refresh `dev/kernel/config/debian-13-amd64`, capture the config and lsmod from `deb13`:

```sh
just vm init deb13
just vm boot deb13
```

Inside deb13:

```sh
mount -t virtiofs drivers /mnt/drivers
cp /boot/config-$(uname -r) /mnt/drivers/
lsmod > /mnt/drivers/lsmod-$(uname -r)
```

Back on the host:

```sh
cp vm/shared/config-<release> dev/kernel/config/debian-13-amd64
```

## Handson

Driver experiments live in `handson/`.
