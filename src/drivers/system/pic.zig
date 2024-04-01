//! The PIC module contains functions for interacting with the Programmable Interrupt Controller 8259.
//!
//! The PIC is a chip that is used to manage interrupts in a computer system.

/// Represents the Programmable Interrupt Controller (PIC).
///
/// The PIC is a hardware component that manages interrupts in a computer system.
/// It allows the system to handle multiple interrupt requests from various devices.
pub const Pic = struct {
    /// The base address of the PIC1.
    pub const PIC1 = 0x20;
    /// The base address of the PIC2.
    pub const PIC2 = 0xA0;

    /// The command port of the PIC1.
    pub const PIC1Command = PIC1;
    /// The data port of the PIC1.
    pub const PIC1Data = PIC1 + 1;
    /// The command port of the PIC2.
    pub const PIC2Command = PIC2;
    /// The data port of the PIC2.
    pub const PIC2Data = PIC2 + 1;

    /// The end of interrupt command.
    pub const PICEOI = 0x20;

    /// The ICW1 ICW4 bit. Specifies whether ICW4 is needed during initialization.
    pub const ICW1ICW4 = 0x01;
    /// The ICW1 Single bit. Specifies whether the PIC is in cascade mode.
    pub const ICW1Single = 0x02;
    /// The ICW1 Interval4 bit. Specifies whether the PIC expects an interval of 4.
    pub const ICW1Interval4 = 0x04;
    /// The ICW1 Level bit. Specifies whether the PIC operates in level-triggered mode.
    pub const ICW1Level = 0x08;
    /// The ICW1 Init bit. Specifies whether the PIC is being initialized.
    pub const ICW1Init = 0x10;

    /// The ICW4 8086/88 bit. Specifies whether the PIC is in 8086/88 mode.
    pub const ICW48086 = 0x01;
    /// The ICW4 Auto bit.
    pub const ICW4Auto = 0x02;
    /// The ICW4 Buffer Slave bit.
    pub const ICW4BufSlave = 0x08;
    /// The ICW4 Buffer Master bit.
    pub const ICW4BufMaster = 0x0C;
    /// The ICW4 Special Fully Nested Mode bit.
    pub const ICW4SFNM = 0x10;

    /// Remap the PIC.
    pub fn remap() void {
        const mask1 = read8(PIC1Data);
        const mask2 = read8(PIC2Data);

        // Start the initialization sequence in cascade mode.
        write8(PIC1Command, ICW1Init | ICW1ICW4);
        write8(PIC2Command, ICW1Init | ICW1ICW4);

        // Set the base interrupt vectors.
        write8(PIC1Data, PIC1);
        write8(PIC2Data, PIC2);

        // Tell the PICs how they are wired to each other.
        write8(PIC1Data, 4);
        write8(PIC2Data, 2);

        // Set the mode.
        write8(PIC1Data, ICW48086);
        write8(PIC2Data, ICW48086);

        // Restore the masks.
        write8(PIC1Data, mask1);
        write8(PIC2Data, mask2);
    }

    /// Receive an 8-bit value from the PIC.
    pub fn read8(port: u16) u8 {
        return asm volatile ("inb %[port], %[result]"
            : [result] "={al}" (-> u8),
            : [port] "N{dx}" (port),
        );
    }

    /// Send an 8-bit value to the PIC.
    pub fn write8(port: u16, value: u8) void {
        asm volatile ("outb %[value], %[port]"
            :
            : [value] "{al}" (value),
              [port] "N{dx}" (port),
        );
    }
};
