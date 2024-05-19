//! The serial module provides a simple interface for reading and writing data over a serial port.

const std = @import("std");

const Pic = @import("system/pic.zig");

/// The error type for the serial module.
pub const SerialError = error{
    InvalidSerialPort,
};

/// The available COM ports.
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

/// The offsets for the registers of the serial port.
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

/// Initializes the serial port to 38400 baud.
pub fn init(port: ComPorts) SerialError!void {
    const portValue: u16 = @intFromEnum(port);

    // Disable all interrupts
    Pic.write8(portValue + RegistersOffsets.InterruptEnable, 0);
    // Enable DLAB (set baud rate divisor)
    Pic.write8(portValue + RegistersOffsets.LineControl, 0x80);

    // 38400 baud
    Pic.write8(portValue + RegistersOffsets.DivisorLow, 3);
    Pic.write8(portValue + RegistersOffsets.DivisorHigh, 0);

    // 8 bits, no parity, one stop bit
    Pic.write8(portValue + RegistersOffsets.LineControl, 0x03);

    // Enable FIFO, clear them, with 14-byte threshold
    Pic.write8(portValue + RegistersOffsets.FifoControl, 0xc7);

    // IRQs enabled, RTS/DSR set
    Pic.write8(portValue + RegistersOffsets.ModemControl, 0x0b);

    // Set in loopback mode to test the serial chip
    Pic.write8(portValue + RegistersOffsets.ModemControl, 0x1e);

    // Test the serial chip (send byte 0xAE and check if it is received)
    Pic.write8(portValue + RegistersOffsets.Data, 0xae);
    if (Pic.read8(portValue + RegistersOffsets.Data) != 0xae)
        return SerialError.InvalidSerialPort;

    // Unset loopback mode
    Pic.write8(portValue + RegistersOffsets.ModemControl, 0x0f);
}

/// Checks if there is data available to read from the serial port.
pub fn is_data_available(port: ComPorts) bool {
    return Pic.read8(@intFromEnum(port) + RegistersOffsets.LineStatus) & 1 == 1;
}

/// Checks if the serial port is ready to write data.
pub fn is_ready_to_write(port: ComPorts) bool {
    return Pic.read8(@intFromEnum(port) + RegistersOffsets.LineStatus) & 0x20 == 0x20;
}

/// Reads a byte from the serial port.
pub fn read(port: ComPorts) u8 {
    while (!is_data_available(port)) {}
    return Pic.read8(@intFromEnum(port) + RegistersOffsets.Data);
}

/// Writes a byte to the serial port.
pub fn writeByte(port: ComPorts, byte: u8) void {
    while (!is_ready_to_write(port)) {}
    Pic.write8(@intFromEnum(port) + RegistersOffsets.Data, byte);
}

/// Writes a string to the serial port.
pub fn write(port: ComPorts, string: []const u8) void {
    for (string) |byte| {
        writeByte(port, byte);
    }
}

const Writer = std.io.Writer(@TypeOf(.{}), error{}, printCallBack);
const writer = Writer{ .context = .{} };

/// Prints a formatted string to the COM1 serial port.
pub fn print(comptime format: []const u8, args: anytype) void {
    std.fmt.format(writer, format, args) catch write(.COM1, "Error while formatting string\n");
}

fn printCallBack(_: @TypeOf(.{}), string: []const u8) error{}!usize {
    write(.COM1, string);
    return string.len;
}
