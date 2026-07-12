const REPO_ROOT = path self ../..

const VM_SPEC = {
    libvirt: {
        uri: "qemu:///system"
        pool: "drivers"
    }
    image: {
        file: "debian-13-nocloud-amd64.qcow2"
        url: "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-nocloud-amd64.qcow2"
        # Published at https://cloud.debian.org/images/cloud/trixie/latest/SHA512SUMS
        sha512: "4bac74c59b8d5f7fe853b0c5e0c5c91ff76b54b0361324dd0c6e361373c694644a538ffe98748e90b46bd598ca0d6567f35fd135bae7728ae212646821dd94b3"
    }
    paths: {
        storage: "vm/storage"
        shared: "vm/shared"
        domains: "vm/domains"
    }
}

# Resolve the shared base image paths from the VM specification.
def resolve-image [spec: record] {
    {
        name: $spec.image.file
        dir: $spec.paths.storage
        path: ([$spec.paths.storage $spec.image.file] | path join)
        url: $spec.image.url
        sha512: $spec.image.sha512
    }
}

# Resolve and validate the paths for a named VM.
def resolve-vm [spec: record, machine: string] {
    let domain_dir = [$spec.paths.domains $machine] | path join
    let volume = $"($machine).qcow2"
    if not ($domain_dir | path exists) {
        error make { msg: $"unknown VM: ($machine)" }
    }

    {
        name: $machine
        image: (resolve-image $spec)
        disk: {
            volume: $volume
            path: ([$spec.paths.storage $volume] | path join)
        }
        shared: ($spec.paths.shared | path expand)
        domain: {
            dir: $domain_dir
            template: ([$domain_dir "domain.tmpl.xml"] | path join)
            xml: ([$domain_dir "domain.xml"] | path join)
        }
    }
}

# Log and run virsh against the configured libvirt connection.
def virsh [libvirt: record, ...args: string] {
    let command = (["virsh" "--connect" $libvirt.uri] | append $args) | str join " "
    print $"command: ($command)"
    ^virsh --connect $libvirt.uri ...$args
    let exit_code = $env.LAST_EXIT_CODE
    if $exit_code != 0 {
        error make {
            msg: $"virsh command failed with exit code ($exit_code): ($args | str join ' ')"
        }
    }
}

# Define the directory-backed storage pool.
def define-pool [spec: record] {
    mkdir $spec.paths.storage
    let target = $spec.paths.storage | path expand
    let args = ["pool-define-as" $spec.libvirt.pool "dir" "--target" $target]
    virsh $spec.libvirt ...$args
}

# Start the defined storage pool.
def start-pool [libvirt: record] {
    virsh $libvirt "pool-start" $libvirt.pool
}

# Show the current storage pool state.
def pool-info [libvirt: record] {
    virsh $libvirt "pool-info" $libvirt.pool
}

# Download the shared base image and register it as a pool volume.
def image [image: record, libvirt: record] {
    mkdir $image.dir

    let downloaded = not ($image.path | path exists)
    let candidate = if $downloaded {
        print $"image: downloading ($image.name)"
        let partial = $"($image.path).part"
        ^curl --fail --location --show-error --output $partial $image.url
        if $env.LAST_EXIT_CODE != 0 {
            rm --force $partial
            error make { msg: $"failed to download image: ($image.url)" }
        }
        $partial
    } else {
        print $"exists: ($image.path)"
        $image.path
    }

    print "image: verifying SHA-512"
    let digest = (^sha512sum $candidate | parse "{sha512}  {path}" | first)
    if $digest.sha512 != $image.sha512 {
        if $downloaded {
            rm --force $candidate
        }
        error make {
            msg: $"image checksum mismatch: expected ($image.sha512), got ($digest.sha512)"
        }
    }
    print "image: checksum verified"

    if $downloaded {
        mv $candidate $image.path
    }

    print $"pool: refreshing ($libvirt.pool)"
    virsh $libvirt "pool-refresh" $libvirt.pool
    print $"volume: ($image.name)"
    virsh $libvirt "vol-info" $image.name "--pool" $libvirt.pool
}

# Create a writable pool volume backed by the shared base image.
def overlay [vm: record, libvirt: record] {
    if ($vm.disk.path | path exists) {
        print $"exists: ($libvirt.pool)/($vm.disk.volume)"
    } else {
        let capacity = (
            ^qemu-img info --output=json $vm.image.path
                | from json
                | get virtual-size
                | into string
        )
        print $"volume: creating ($vm.disk.volume)"
        let args = [
            "vol-create-as"
            $libvirt.pool
            $vm.disk.volume
            $capacity
            "--format"
            "qcow2"
            "--backing-vol"
            $vm.image.name
            "--backing-vol-format"
            "qcow2"
        ]
        virsh $libvirt ...$args
    }
    print $"volume: ($vm.disk.volume)"
    virsh $libvirt "vol-info" $vm.disk.volume "--pool" $libvirt.pool
}

# Render a domain XML with host-specific paths.
def domain [vm: record] {
    mkdir $vm.domain.dir
    mkdir $vm.shared
    with-env {
        SHARED_DIR: $vm.shared
    } {
        open --raw $vm.domain.template
            | decode utf-8
            | ^envsubst '$SHARED_DIR'
            | save --force $vm.domain.xml
    }
    print $"domain: rendered ($vm.domain.xml)"
}

# Define a persistent, initially stopped domain from its rendered XML.
def define-domain [vm: record, libvirt: record] {
    print $"domain: defining ($vm.name)"
    virsh $libvirt "define" $vm.domain.xml "--validate"
    virsh $libvirt "dominfo" $vm.name
}

# Start a previously defined domain, optionally attached to its console.
def start-domain [vm: record, libvirt: record, --console] {
    print $"domain: starting ($vm.name)"
    if $console {
        print "console: attaching during boot; detach with Ctrl+]"
        virsh $libvirt "start" $vm.name "--console"
    } else {
        virsh $libvirt "start" $vm.name
        virsh $libvirt "domstate" $vm.name
    }
}

# Attach the terminal to a running domain's serial console.
def console [vm: record, libvirt: record] {
    print $"console: attaching to ($vm.name); detach with Ctrl+]"
    virsh $libvirt "console" $vm.name
}

# Dispatch a VM command from the Just module.
def main [command: string, machine?: string] {
    cd $REPO_ROOT

    match $command {
        "pool-define" => { define-pool $VM_SPEC }
        "pool-start" => { start-pool $VM_SPEC.libvirt }
        "pool-info" => { pool-info $VM_SPEC.libvirt }
        "image" => { image (resolve-image $VM_SPEC) $VM_SPEC.libvirt }
        "overlay" => { overlay (resolve-vm $VM_SPEC $machine) $VM_SPEC.libvirt }
        "domain" => { domain (resolve-vm $VM_SPEC $machine) }
        "define" => { define-domain (resolve-vm $VM_SPEC $machine) $VM_SPEC.libvirt }
        "start" => { start-domain (resolve-vm $VM_SPEC $machine) $VM_SPEC.libvirt }
        "boot" => { start-domain (resolve-vm $VM_SPEC $machine) $VM_SPEC.libvirt --console }
        "console" => { console (resolve-vm $VM_SPEC $machine) $VM_SPEC.libvirt }
        _ => { error make { msg: $"unknown VM command: ($command)" } }
    }
}
