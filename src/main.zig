const Cpu = @import("drivers/system/cpu.zig").Cpu;
const Pic = @import("drivers/system/pic.zig").Pic;

/// This function is the entry point of the kernel.
/// It is called by the bootloader after the kernel is loaded into memory.
/// It is marked as `noreturn` because it should never return.
export fn _start() callconv(.C) noreturn {
    // Initialize the PIC
    Pic.remap();
    Cpu.disable_interrupts();
    Cpu.halt();
}
