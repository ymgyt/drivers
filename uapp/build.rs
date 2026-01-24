use std::{
    env, fs,
    path::{Path, PathBuf},
};

struct BindingSpecs<'a> {
    header: &'a str,
    out_rs: &'a str,
}

fn generate(spec: &BindingSpecs, manifest_dir: &Path) {
    println!("cargo:rerun-if-changed={}", spec.header);

    let bindings = bindgen::Builder::default()
        .header(spec.header)
        .generate()
        .expect("bindgen failed");

    let out = manifest_dir.join("src/generated").join(spec.out_rs);
    if let Some(parent) = out.parent() {
        fs::create_dir_all(parent).unwrap();
    }
    bindings.write_to_file(&out).expect("cannot write bindings");
}

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let specs = [BindingSpecs {
        header: "../devone/devone_ioctl.h",
        out_rs: "devone_ioctl_bindings.rs",
    }];

    for s in &specs {
        generate(s, &manifest_dir);
    }
}
