obj-m := hello.o

KDIR ?= $(K_DIR)
PWD := $(shell pwd)

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

insmod:
	sudo insmod ./hello.ko
	sudo dmesg -T | rg "hello:"

rmmod:
	sudo rmmod hello
	sudo dmesg -T | rg "hello:"
