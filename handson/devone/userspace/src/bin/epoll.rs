use std::{fs::OpenOptions, io, mem, os::fd::AsRawFd as _};

use anyhow::bail;
use tracing::info;

fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let f = OpenOptions::new()
        .read(true)
        .write(true)
        .open("/dev/devone0")?;
    let fd = f.as_raw_fd();

    let epfd = unsafe { libc::epoll_create1(0) };
    if epfd < 0 {
        bail!(io::Error::last_os_error());
    }

    let mut ev: libc::epoll_event = unsafe { mem::zeroed() };
    ev.events = libc::EPOLLIN as u32;

    ev.u64 = fd as u64;

    let rc = unsafe { libc::epoll_ctl(epfd, libc::EPOLL_CTL_ADD, fd, &mut ev as *mut _) };
    if rc < 0 {
        let err = io::Error::last_os_error();
        unsafe { libc::close(epfd) };
        bail!(err)
    }

    let mut events: [libc::epoll_event; 8] = unsafe { mem::zeroed() };

    let n = unsafe { libc::epoll_wait(epfd, events.as_mut_ptr(), events.len() as i32, 0) };
    if n < 0 {
        let err = io::Error::last_os_error();
        unsafe { libc::close(epfd) };
        bail!(err)
    }

    info!("epoll_wait retruned n={n}");
    #[expect(clippy::needless_range_loop)]
    for i in 0..n as usize {
        let ev = &events[i];
        let ready = ev.events;
        let token = ev.u64;
        info!("event[{i}]: token={token} events=0x{ready:x}");
        if ready & (libc::EPOLLIN as u32) != 0 {
            info!("  => EPOLLIN (redable)");
        }
    }

    unsafe { libc::close(epfd) };
    Ok(())
}
