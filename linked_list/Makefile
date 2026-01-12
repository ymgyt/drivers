obj-m := linked_list.o

MOD_NAME := "linked_list"
KDIR ?= $(K_DIR)
PWD := $(shell pwd)

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

insmod:
	sudo insmod ./linked_list.ko
	sudo dmesg -T | rg $(MOD_NAME):

rmmod:
	sudo rmmod linked_list
	sudo dmesg -T | rg $(MOD_NAME):
