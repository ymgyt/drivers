// SPDX-License-Identifier: GPL-2.0

//! Minimal Rust kernel module for the misc device.

use core::ptr;

use kernel::{
    container_of,
    fs::{File, Kiocb},
    iov::{IovIterDest, IovIterSource},
    miscdevice::{MiscDevice, MiscDeviceOptions, MiscDeviceRegistration},
    new_mutex,
    prelude::*,
    sync::{Arc, Mutex},
};

module! {
    type: MiscDrvModule,
    name: "miscdrv",
    authors: ["ymgyt"],
    description: "Rust misc device",
    license: "GPL",
}

#[pin_data]
struct DeviceState {
    #[pin]
    message: Mutex<KVVec<u8>>,
}

impl DeviceState {
    fn new() -> impl PinInit<Self> {
        pin_init!(Self {
            message <- new_mutex!(KVVec::new()),
        })
    }
}

#[pin_data]
struct MiscDrvModule {
    state: Arc<DeviceState>,
    #[pin]
    _miscdev: MiscDeviceRegistration<DeviceOps>,
}

impl kernel::InPlaceModule for MiscDrvModule {
    fn init(_module: &'static ThisModule) -> impl PinInit<Self, Error> {
        let options = MiscDeviceOptions { name: c"miscdrv" };

        pr_info!("loaded\n");

        try_pin_init!(Self {
            state: Arc::pin_init(DeviceState::new(), GFP_KERNEL)?,
            _miscdev <- MiscDeviceRegistration::register(options),
        })
    }
}

struct DeviceOps;

struct OpenContext {
    state: Arc<DeviceState>,
}

#[vtable]
impl MiscDevice for DeviceOps {
    type Ptr = KBox<OpenContext>;

    fn open(_file: &File, reg: &MiscDeviceRegistration<Self>) -> Result<Self::Ptr> {
        reg.device().pr_info(format_args!("opened\n"));

        // SAFETY:
        // - `reg` points to `MiscDrvModule::_miscdev` because `DeviceOps` is registered only there.
        // - `MiscDrvModule` is pinned, so its address does not change.
        // - The miscdevice core keeps `reg` alive for the duration of `open()`.
        let module: &MiscDrvModule =
            unsafe { &*container_of!(ptr::from_ref(reg), MiscDrvModule, _miscdev) };

        Ok(KBox::new(
            OpenContext {
                state: module.state.clone(),
            },
            GFP_KERNEL,
        )?)
    }

    fn read_iter(mut kiocb: Kiocb<'_, Self::Ptr>, iov: &mut IovIterDest<'_>) -> Result<usize> {
        let ctx: &OpenContext = kiocb.file();
        let message = ctx.state.message.lock();
        let num_written = iov.simple_read_from_buffer(kiocb.ki_pos_mut(), &message)?;

        Ok(num_written)
    }

    fn write_iter(
        mut kiocb: Kiocb<'_, Self::Ptr>,
        iov: &mut IovIterSource<'_>,
    ) -> Result<usize> {
        let ctx: &OpenContext = kiocb.file();

        let num_written = {
            let mut message = ctx.state.message.lock();
            message.clear();
            iov.copy_from_iter_vec(&mut *message, GFP_KERNEL)?
        };

        *kiocb.ki_pos_mut() = 0;

        Ok(num_written)
    }
}
