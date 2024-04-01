//! The CPU module contains functions for interacting with the CPU.

/// The CPU struct contains functions for interacting with the CPU.
pub const Cpu = struct {
    /// The `disable_interrupts` function disables interrupts.
    pub fn disable_interrupts() void {
        asm volatile ("cli");
    }

    /// The `enable_interrupts` function enables interrupts.
    pub fn enable_interrupts() void {
        asm volatile ("sti");
    }

    /// The `halt` function halts the CPU.
    /// This function will halt the CPU until an interrupt is received.
    pub fn halt() noreturn {
        while (true) {
            asm volatile ("hlt");
        }
    }
};
