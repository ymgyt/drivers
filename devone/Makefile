obj-m := devone.o

MOD_NAME := "devone"
KDIR ?= $(K_DIR)
PWD := $(shell pwd)

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

insmod:
	sudo insmod ./devone.ko
	sudo dmesg -T | rg $(MOD_NAME):

rmmod:
	sudo rmmod devone
	sudo dmesg -T | rg $(MOD_NAME):
