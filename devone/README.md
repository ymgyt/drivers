# devone

## udev rule

```sh
cat <<EOF > /run/udev/rules.d/51-devone.rules
KERNEL=="devone[0-9]*", GROUP="root" MODE="0644"
EOF
```

## userspace app

```sh
make modules
make insmod

cd ../uapp
cargo run --bin devone_ioctl
```
