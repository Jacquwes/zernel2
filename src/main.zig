/// This function is the entry point of the kernel.
/// It is called by the bootloader after the kernel is loaded into memory.
/// It is marked as `noreturn` because it should never return.
export fn _start() callconv(.C) noreturn {
    halt();
}

pub fn halt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
