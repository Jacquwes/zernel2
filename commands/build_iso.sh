#! /bin/sh

mkdir -p iso_root/EFI/BOOT
cp -v zig-out/bin/zernel2 limine.cfg limine/limine-bios.sys limine/limine-bios-cd.bin limine/limine-uefi-cd.bin iso_root
cp -v limine/BOOTX64.EFI iso_root/EFI/BOOT/BOODX64.EFI

xorriso -as mkisofs -b limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label iso_root -o zernel2.iso

./limine/limine bios-install zernel2.iso