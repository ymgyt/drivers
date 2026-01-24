use tracing::info;
use uapp::devone_ioctl::IOC_MAGIC;

fn main() {
    tracing_subscriber::fmt::init();

    info!("{}", IOC_MAGIC);
}
