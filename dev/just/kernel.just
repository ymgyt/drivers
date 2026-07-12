linux_source := justfile_directory() / ".." / "linux"
kernel_build := justfile_directory() / ".build" / "rust-next"
root_justfile := justfile_directory() / "justfile"
build_jobs := num_cpus()
cc := env_var("CC")
hostcc := env_var("HOSTCC")
hostcxx := env_var("HOSTCXX")
bindgen := env_var("BINDGEN")

[private]
default:
    @just --justfile "{{ root_justfile }}" --unsorted --list kernel

[private]
make *args:
    make -C "{{ linux_source }}" "O={{ kernel_build }}" LLVM=1 "CC={{ cc }}" "HOSTCC={{ hostcc }}" "HOSTCXX={{ hostcxx }}" "BINDGEN={{ bindgen }}" {{ args }}

[private]
config *args:
    "{{ linux_source }}/scripts/config" --file "{{ kernel_build }}/.config" {{ args }}

# Update the existing .config for the current rust-next Kconfig.
olddefconfig: (make "olddefconfig")

# Request Rust support in the kernel configuration.
rustconfig: (config "--enable" "GENDWARFKSYMS" "--enable" "RUST")

# Build the drivers needed to boot the development VM into the kernel.
vmconfig: (config "--enable" "VIRTIO_MENU" "--enable" "VIRTIO_PCI" "--enable" "VIRTIO_BLK" "--enable" "EXT4_FS" "--enable" "EFI_PARTITION" "--enable" "FUSE_FS" "--enable" "VIRTIO_FS" "--enable" "SERIAL_8250" "--enable" "SERIAL_8250_CONSOLE")

# Configure the kernel interactively.
menuconfig: (make "menuconfig")

# Build the x86 bootable kernel image using all host CPUs.
image: (make ("-j" + build_jobs) "bzImage")
