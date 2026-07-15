ifneq ($(KERNELRELEASE),)
obj-m := miscdrv.o
else
KDIR ?= ../../../.build/rust-next

.PHONY: modules modules_prepare clean

modules: modules_prepare
	$(MAKE) -C "$(KDIR)" M="$$PWD" $(KERNEL_MAKE_ARGS) modules

modules_prepare:
	$(MAKE) -C "$(KDIR)" $(KERNEL_MAKE_ARGS) modules_prepare

clean:
	$(MAKE) -C "$(KDIR)" M="$$PWD" clean
endif
