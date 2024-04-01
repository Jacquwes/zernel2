//! The serial module provides a simple interface for reading and writing data over a serial port.

const Pic = @import("system/pic.zig").Pic;

pub const SerialError = error{
    InvalidSerialPort,
};

pub const Serial = struct {
    pub const ComPorts = enum(u16) {
        COM1 = 0x3f8,
        COM2 = 0x2f8,
        COM3 = 0x3e8,
        COM4 = 0x2e8,
        COM5 = 0x5f8,
        COM6 = 0x4f8,
        COM7 = 0x5e8,
        COM8 = 0x4e8,
    };

    pub const RegistersOffsets = struct {
        pub const Data = 0;
        pub const InterruptEnable = 1;
        pub const DivisorLow = 0;
        pub const DivisorHigh = 1;
        pub const InterruptIdentification = 2;
        pub const FifoControl = 2;
        pub const LineControl = 3;
        pub const ModemControl = 4;
        pub const LineStatus = 5;
        pub const ModemStatus = 6;
        pub const Scratch = 7;
    };

    pub fn init(port: ComPorts) SerialError!void {
        // Disable all interrupts
        Pic.write8(@intFromEnum(port) + RegistersOffsets.InterruptEnable, 0);
        // Enable DLAB (set baud rate divisor)
        Pic.write8(@intFromEnum(port) + RegistersOffsets.LineControl, 0x80);

        // 38400 baud
        Pic.write8(@intFromEnum(port) + RegistersOffsets.DivisorLow, 3);
        Pic.write8(@intFromEnum(port) + RegistersOffsets.DivisorHigh, 0);

        // 8 bits, no parity, one stop bit
        Pic.write8(@intFromEnum(port) + RegistersOffsets.LineControl, 0x03);

        // Enable FIFO, clear them, with 14-byte threshold
        Pic.write8(@intFromEnum(port) + RegistersOffsets.FifoControl, 0xc7);

        // IRQs enabled, RTS/DSR set
        Pic.write8(@intFromEnum(port) + RegistersOffsets.ModemControl, 0x0b);

        // Set in loopback mode to test the serial chip
        Pic.write8(@intFromEnum(port) + RegistersOffsets.ModemControl, 0x1e);

        // Test the serial chip (send byte 0xAE and check if it is received)
        Pic.write8(@intFromEnum(port) + RegistersOffsets.Data, 0xae);
        if (Pic.read8(@intFromEnum(port) + RegistersOffsets.Data) != 0xae)
            return SerialError.InvalidSerialPort;

        // Unset loopback mode
        Pic.write8(@intFromEnum(port) + RegistersOffsets.ModemControl, 0x0f);
    }
};
