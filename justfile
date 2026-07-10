set shell := ["nu", "--commands"]

image_name := "debian-13-nocloud-amd64.qcow2"
image_url := "https://cloud.debian.org/images/cloud/trixie/latest/" + image_name
images_dir := "vm" / "images"
image_path := images_dir / image_name

domain := "edu-deb13"
domain_dir := "vm" / "domains" / domain
domain_template_path := domain_dir / "domain.tmpl.xml"
domain_path := domain_dir / "domain.xml"
overlay_path := domain_dir / "overlay.qcow2"
overlay_backing_path := ".." / ".." / "images" / image_name

default: list

# List tasks.
list:
    @just --list --unsorted --list-submodules

# Initialize VM files.
init: domain

# Download the Debian cloud image.
image:
    #!/usr/bin/env nu
    mkdir "{{ images_dir }}"
    if ("{{ image_path }}" | path exists) {
        print "exists: {{ image_path }}"
    } else {
        curl --fail --location --show-error --output "{{ image_path }}" "{{ image_url }}"
    }

# Create the writable domain overlay image.
overlay: image
    #!/usr/bin/env nu
    mkdir "{{ domain_dir }}"
    if ("{{ overlay_path }}" | path exists) {
        print "exists: {{ overlay_path }}"
    } else {
        qemu-img create -f qcow2 -F qcow2 -b "{{ overlay_backing_path }}" "{{ overlay_path }}"
    }

# Render the libvirt domain XML.
domain: overlay
    #!/usr/bin/env nu
    let overlay = ("{{ overlay_path }}" | path expand)
    with-env { OVERLAY_QCOW2: $overlay } {
        open --raw "{{ domain_template_path }}"
            | decode utf-8
            | envsubst '$OVERLAY_QCOW2'
            | save --force "{{ domain_path }}"
    }
    print "rendered: {{ domain_path }}"

# Remove generated VM images.
clean:
    rm --force "{{ domain_path }}"
    rm --force "{{ overlay_path }}"
