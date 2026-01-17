# Kernel Drivers

## hello

```sh
cd hello

make modules
make insmod
make rmmod
```


## clangd

```sh
cd foo
bear --append --output ../compile_commands.json -- make -C $K_DIR M=$(pwd) HOSTCC=cc modules
```
