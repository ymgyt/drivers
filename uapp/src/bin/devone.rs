use std::{
    env, fs,
    io::{Read as _, Write as _},
};

use tracing::info;

fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let dev_file = env::var("DEV_FILE").unwrap_or("/dev/devone".to_owned());

    let mut f = fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(dev_file)?;

    let mut buf = [0; 8];

    f.write_all(b"A")?;
    f.read_exact(&mut buf)?;
    info!("Read: {}", String::from_utf8_lossy(&buf));

    f.write_all(b"B")?;
    f.read_exact(&mut buf)?;
    info!("Read: {}", String::from_utf8_lossy(&buf));

    Ok(())
}
