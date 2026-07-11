vm_script := justfile_directory() / "dev" / "scripts" / "vm.nu"
root_justfile := justfile_directory() / "justfile"

[private]
default:
    @just --justfile "{{ root_justfile }}" --unsorted --list vm pool

# Define the storage pool.
define:
    @nu "{{ vm_script }}" pool-define

# Start the storage pool.
start:
    @nu "{{ vm_script }}" pool-start

# Show the storage pool state.
info:
    @nu "{{ vm_script }}" pool-info
