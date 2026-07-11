vm_script := justfile_directory() / "dev" / "scripts" / "vm.nu"
root_justfile := justfile_directory() / "justfile"

# Storage pool tasks
mod pool "vm/pool.just"

[private]
default:
    @just --justfile "{{ root_justfile }}" --unsorted --list vm

# Initialize and define a stopped VM.
init machine: (define machine)

# Download the Debian cloud image.
image:
    @nu "{{ vm_script }}" image

# Create a writable pool volume backed by the base image.
overlay machine: image
    @nu "{{ vm_script }}" overlay "{{ machine }}"

# Render a domain XML that references the VM's pool volume.
domain machine: (overlay machine)
    @nu "{{ vm_script }}" domain "{{ machine }}"

# Define a persistent, stopped domain from its rendered XML.
define machine: (domain machine)
    @nu "{{ vm_script }}" define "{{ machine }}"

# Start a previously defined domain.
start machine:
    @nu "{{ vm_script }}" start "{{ machine }}"

# Start a domain and attach to its console during boot.
boot machine:
    @nu "{{ vm_script }}" boot "{{ machine }}"

# Attach to a running domain's serial console.
console machine:
    @nu "{{ vm_script }}" console "{{ machine }}"
