use std::{fs::OpenOptions, io, os::fd::AsRawFd as _};

use tracing::info;
use uapp::bindings::devone_ioctl::{IOCTL_VALGET, IOCTL_VALSET, ioctl_cmd};

fn ioctl_valset(fd: i32, val: u32) -> io::Result<()> {
    let mut data = ioctl_cmd {
        reg: 0,
        offset: 0,
        val,
    };

    let rc = unsafe { libc::ioctl(fd, IOCTL_VALSET as libc::c_ulong, &mut data) };
    if rc < 0 {
        return Err(io::Error::last_os_error());
    }
    Ok(())
}

fn ioctl_valget(fd: i32) -> io::Result<u32> {
    let mut data = ioctl_cmd {
        reg: 0,
        offset: 0,
        val: 0,
    };

    let rc = unsafe { libc::ioctl(fd, IOCTL_VALGET as libc::c_ulong, &mut data) };
    if rc < 0 {
        return Err(io::Error::last_os_error());
    }
    Ok(data.val)
}

fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let f = OpenOptions::new()
        .read(true)
        .write(true)
        .open("/dev/devone0")?;
    let fd = f.as_raw_fd();

    let got = ioctl_valget(fd)?;
    info!("IOCTL_VALGET: got val=0x{got:02x}");

    let set_val = 2_u32;
    info!("IOCTL_VALSET: setting val=0x{set_val:02x}");
    ioctl_valset(fd, set_val)?;

    let got = ioctl_valget(fd)?;
    info!("IOCTL_VALGET: got val=0x{got:02x}");

    Ok(())
}
