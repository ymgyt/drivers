use std::{env, path::PathBuf};

const HEADER: &str = "../module/devone_ioctl.h";

fn main() {
    println!("cargo:rerun-if-changed={HEADER}");

    let bindings = bindgen::Builder::default()
        .header(HEADER)
        .generate()
        .expect("bindgen failed");

    let out = PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR is not set"))
        .join("devone_ioctl_bindings.rs");
    bindings.write_to_file(out).expect("cannot write bindings");
}
