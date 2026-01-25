# devone

## udev rule

```sh
cat <<EOF | sudo tee /run/udev/rules.d/51-devone.rules > /dev/null
KERNEL=="devone[0-9]*", GROUP="root",  MODE="0644"
EOF
```

## userspace app

```sh
make modules
make insmod

cd ../uapp
cargo run --bin devone_ioctl
```
