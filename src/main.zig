const cpu = @import("drivers/system/cpu.zig");
const gdt = @import("drivers/system/gdt.zig");
const pic = @import("drivers/system/pic.zig");
const serial = @import("drivers/serial.zig");
const terminal = @import("drivers/terminal.zig");

/// This function is the entry point of the kernel.
/// It is called by the bootloader after the kernel is loaded into memory.
/// It is marked as `noreturn` because it should never return.
export fn _start() callconv(.C) noreturn {
    // Initialize the PIC
    pic.remap();

    // Initialize the serial port
    serial.init(.COM1) catch unreachable;
    serial.write(.COM1, "Zernel2 serial communication initialized.\n\r");


    // Initialize the terminal
    terminal.init() catch serial.write(.COM1, "Failed to initialize terminal.\n\r");
    terminal.putString("Zernel2 terminal initialized.\n\r");
    terminal.putString("_start is at: ");

    // Stop the cpu
    cpu.disable_interrupts();
    cpu.halt();
}
