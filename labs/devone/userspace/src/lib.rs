pub mod bindings {
    pub mod devone_ioctl {
        #![allow(non_camel_case_types)]
        include!(concat!(env!("OUT_DIR"), "/devone_ioctl_bindings.rs"));
    }
}
