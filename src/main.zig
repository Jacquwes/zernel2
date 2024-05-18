const Cpu = @import("drivers/system/cpu.zig");
const Pic = @import("drivers/system/pic.zig");
const Serial = @import("drivers/serial.zig");

/// This function is the entry point of the kernel.
/// It is called by the bootloader after the kernel is loaded into memory.
/// It is marked as `noreturn` because it should never return.
export fn _start() callconv(.C) noreturn {
    // Initialize the PIC
    Pic.remap();

    // Initialize the serial port
    Serial.init(Serial.ComPorts.COM1) catch unreachable;
    Serial.write(Serial.ComPorts.COM1, "Zernel2 serial communication initialized.\n\r");

    // Stop the cpu
    Cpu.disable_interrupts();
    Cpu.halt();
}
