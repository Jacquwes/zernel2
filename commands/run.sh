#! /bin/sh

qemu-system-x86_64 \
    -drive format=raw,file=zernel2.iso \
    -serial stdio \
    -s\
    -D qemu.log -d cpu_reset,int \
    -drive format=raw,file=hd.img \
    -no-reboot