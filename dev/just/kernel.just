linux_source := justfile_directory() / ".." / "linux"
kernel_build := justfile_directory() / ".build" / "rust-next"
kernel_config := justfile_directory() / "dev" / "kernel" / "config" / "debian-13-amd64"
root_justfile := justfile_directory() / "justfile"
build_jobs := num_cpus()
kernel_make_args := env_var("KERNEL_MAKE_ARGS")

[private]
default:
    @just --justfile "{{ root_justfile }}" --unsorted --list kernel

[private]
make *args:
    make -C "{{ linux_source }}" "O={{ kernel_build }}" {{ kernel_make_args }} {{ args }}

# Check whether the Rust toolchain required by the kernel is available.
rustavailable: (make "rustavailable")

[private]
config *args:
    "{{ linux_source }}/scripts/config" --file "{{ kernel_build }}/.config" {{ args }}

# Reset .config from the tracked Debian seed configuration.
initconfig:
    mkdir -p "{{ kernel_build }}"
    cp --force "{{ kernel_config }}" "{{ kernel_build }}/.config"

# Update the existing .config for the current rust-next Kconfig.
olddefconfig: (make "olddefconfig")

# Compare the current .config with the tracked Debian seed configuration.
diffconfig:
    "{{ linux_source }}/scripts/diffconfig" "{{ kernel_config }}" "{{ kernel_build }}/.config"

# Request Rust support in the kernel configuration.
rustconfig: (config "--enable" "GENDWARFKSYMS" "--enable" "RUST")

# Build the drivers needed to boot the development VM into the kernel.
vmconfig: (config "--enable" "VIRTIO_MENU" "--enable" "VIRTIO_PCI" "--enable" "VIRTIO_BLK" "--enable" "EXT4_FS" "--enable" "EFI_PARTITION" "--enable" "FUSE_FS" "--enable" "VIRTIO_FS" "--enable" "SERIAL_8250" "--enable" "SERIAL_8250_CONSOLE" "--enable" "VFAT_FS" "--enable" "NLS_CODEPAGE_437" "--enable" "NLS_ASCII" "--enable" "EFIVAR_FS")

# Prune modules not observed in an explicit target lsmod snapshot.
localmodconfig lsmod:
    yes "" | make -C "{{ linux_source }}" "O={{ kernel_build }}" {{ kernel_make_args }} "LSMOD={{ justfile_directory() / lsmod }}" localmodconfig

# Configure the kernel interactively.
menuconfig: (make "menuconfig")

# Build the x86 bootable kernel image using all host CPUs.
image: (make ("-j" + build_jobs) "bzImage")

# Build in-tree kernel modules and generate Module.symvers.
modules: (make ("-j" + build_jobs) "modules")
