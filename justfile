set shell := ["nu", "--commands"]

# VM tasks
mod vm "dev/just/vm.just"

[private]
default:
    @just --list --unsorted
