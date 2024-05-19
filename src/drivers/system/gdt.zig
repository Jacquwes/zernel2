//! This module contains functions for interacting with the Global Descriptor Table (Gdt).

const cpu = @import("cpu.zig");

/// Represents the Gdt.
pub const GdtDescriptor = packed struct(u80) {
    /// The size of the Gdt.
    limit: u16,
    /// The base address of the Gdt.
    base: u64,
};

/// A struct representing an access byte in a Gdt entry.
pub const DataCodeAccessByte = packed struct(u8) {
    accessed: u1,
    read_write: u1,
    direction_conforming: u1,
    code: u1,
    descriptor_type: u1,
    privilege: u2,
    present: u1,
};

/// A struct representing an access byte for a system segment in a Gdt entry.
pub const SystemAccessByte = packed struct(u8) {
    pub const SystemSegmentTypeLong = enum(u4) {
        LDT = 0x2,
        Tss64Available = 0x9,
        Tss64Busy = 0xB,
    };

    type: SystemSegmentTypeLong,
    descriptor_type: u1,
    privilege: u2,
    present: u1,
};

/// A struct representing a flags byte in a Gdt entry.
pub const FlagsByte = packed struct(u4) {
    _: u1 = 0,
    long_mode: u1,
    size: u1,
    granularity: u1,
};

/// A struct representing a Gdt entry.
pub const GdtEntry = packed struct(u64) {
    limit_low: u16,
    base_low: u24,
    access: DataCodeAccessByte,
    limit_high: u4,
    flags: FlagsByte,
    base_high: u8,

    /// Returns the base address of the segment.
    pub fn base(self: GdtEntry) u64 {
        return self.base_low | @as(u64, (self.base_high)) << 24;
    }

    /// Returns the limit of the segment.
    pub fn limit(self: GdtEntry) u64 {
        return self.limit_low | @as(u64, (self.limit_high)) << 16;
    }

    pub fn nullDescriptor() GdtEntry {
        return @bitCast(@as(u64, 0));
    }
};

/// A struct representing a system Gdt entry.
pub const SystemGdtEntry = packed struct(u128) {
    limit_low: u16,
    base_low: u24,
    access: SystemAccessByte,
    limit_high: u4,
    flags: FlagsByte,
    base_high: u40,
    reserved: u32,
};

/// Creates a Gdt entry.
pub fn createGdtEntry(base: u64, limit: u64, access: DataCodeAccessByte, flags: FlagsByte) GdtEntry {
    return GdtEntry{
        .access = access,
        .base_high = @truncate(base >> 24),
        .base_low = @truncate(base),
        .flags = flags,
        .limit_high = @truncate(limit >> 16),
        .limit_low = @truncate(limit),
    };
}

/// The Gdt entries.
const gdtEntries = [_]GdtEntry{
    GdtEntry.nullDescriptor(),
    createGdtEntry(0, 0, .{
        .present = 1,
        .privilege = 0,
        .descriptor_type = 1,
        .code = 1,
        .direction_conforming = 0,
        .read_write = 1,
        .accessed = 0,
    }, .{
        .granularity = 1,
        .size = 0,
        .long_mode = 1,
    }),
    createGdtEntry(0, 0, .{
        .present = 1,
        .privilege = 0,
        .descriptor_type = 1,
        .code = 0,
        .direction_conforming = 0,
        .read_write = 1,
        .accessed = 0,
    }, .{
        .granularity = 1,
        .size = 1,
        .long_mode = 0,
    }),
};

/// Initializes the Gdt.
pub fn init() void {
    const write = @import("../serial.zig").write;

    write(.COM1, "Setting up GDTR\n");
    const gdtDescriptor = GdtDescriptor{
        .limit = @sizeOf(@TypeOf(gdtEntries)) - 1,
        .base = @intFromPtr(&gdtEntries[0]),
    };

    write(.COM1, "Disabling interrupts\n");
    cpu.disable_interrupts();

    write(.COM1, "Loading GDTR\n");
    asm volatile (
        \\lgdt %[gdt]
        \\mov %[ds], %rax
        \\movq %rax, %ds
        \\movq %rax, %es
        \\movq %rax, %fs
        \\movq %rax, %gs
        \\movq %rax, %ss
        \\pushq %[cs]
        \\lea 1f(%rip), %rax
        \\pushq %rax
        \\lretq
        \\1:
        :
        : [gdt] "*p" (&gdtDescriptor),
          [ds] "i" (0x10),
          [cs] "i" (0x08),
        : "memory"
    );

    write(.COM1, "Setting up GDTR done\n");
}

const std = @import("std");
const testing = std.testing;

test "Null descriptor" {
    const entry = GdtEntry.nullDescriptor();
    try testing.expect(@as(u64, @bitCast(entry)) == 0);
}

test "Create kernel code segment" {
    const entry = createGdtEntry(0, 0, .{
        .present = 1,
        .privilege = 0,
        .descriptor_type = 1,
        .code = 1,
        .direction_conforming = 0,
        .read_write = 1,
        .accessed = 0,
    }, .{
        .granularity = 1,
        .size = 0,
        .long_mode = 1,
    });

    try testing.expect(@as(u64, @bitCast(entry)) == 0x00A0_9A00_0000_0000);
}

test "Create kernel data segment" {
    const entry = createGdtEntry(0, 0, .{
        .present = 1,
        .privilege = 0,
        .descriptor_type = 1,
        .code = 0,
        .direction_conforming = 0,
        .read_write = 1,
        .accessed = 0,
    }, .{
        .granularity = 1,
        .size = 1,
        .long_mode = 0,
    });

    try testing.expect(@as(u64, @bitCast(entry)) == 0x00C0_9200_0000_0000);
}
