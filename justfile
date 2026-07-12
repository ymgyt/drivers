set shell := ["nu", "--commands"]

# VM tasks
mod vm "dev/just/vm/mod.just"

# Kernel tasks
mod kernel "dev/just/kernel.just"

[private]
default:
    @just --list --unsorted
