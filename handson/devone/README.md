# devone

## udev rule

```sh
cat <<EOF | sudo tee /run/udev/rules.d/51-devone.rules > /dev/null
KERNEL=="devone[0-9]*", GROUP="root",  MODE="0644"
EOF
```

## userspace app

```sh
make -C module modules
make -C module insmod
cargo run --manifest-path userspace/Cargo.toml --bin ioctl
```
