#! /bin/sh

gdb-multiarch -ex "target remote localhost:1234" -ex "symbol-file ./zig-out/bin/zernel2"