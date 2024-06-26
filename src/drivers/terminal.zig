//! The `terminal` module provides a simple interface for writing text to the screen.

const std = @import("std");
const limine = @import("limine");

export var framebufferRequest: limine.FramebufferRequest = .{};

const fontFile = @embedFile("font.psf");

const PsfFontMagic = 0x864AB572;
const PsfHeader = packed struct {
    magic: u32,
    version: u32,
    headerSize: u32,
    flags: u32,
    glyphCount: u32,
    glyphSize: u32,
    fontHeight: u32,
    fontWidth: u32,
};

pub const Cursor = struct {
    x: u64,
    y: u64,
};

var cursor: Cursor = .{ .x = 0, .y = 0 };
var height: u64 = 0;
var width: u64 = 0;

var foregroundColor: u32 = 0xFFFFFF;
var backgroundColor: u32 = 0x000000;

var framebuffer: *limine.Framebuffer = undefined;

const font: PsfHeader = @bitCast(fontFile[0..@sizeOf(PsfHeader)].*);

const PrintError = error{};
const Writer = std.io.Writer(void, PrintError, printCallback);

fn printCallback(context: void, string: []const u8) PrintError!usize {
    _ = context;
    putString(string);
    return string.len;
}

pub const TerminalError = error{
    InvalidFramebufferRequest,
};

fn drawPixel(x: u64, y: u64, color: u32) void {
    const pixelOffset = framebuffer.pitch * y + x * framebuffer.bpp / 8;
    @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixelOffset))).* = color;
}

pub fn init() !void {
    if (framebufferRequest.response) |response| {
        if (response.framebuffer_count > 0) {
            framebuffer = response.framebuffers()[0];
            height = framebuffer.height;
            width = framebuffer.width;
        } else {
            return TerminalError.InvalidFramebufferRequest;
        }
    } else {
        return TerminalError.InvalidFramebufferRequest;
    }
}

pub fn clear() void {
    for (0..height) |line| {
        for (0..width) |column| {
            drawPixel(column, line, backgroundColor);
        }
    }
}

pub fn putChar(char: u8) void {
    if (char == '\n') {
        cursor.x = 0;
        cursor.y += 1;
        return;
    } else if (char == '\r') {
        cursor.x = 0;
        return;
    } else if (char == '\t') {
        cursor.x += cursor.x % 4;
        return;
    }

    for (0..font.fontHeight) |y| {
        var pixelMask: u8 = 1;
        for (0..font.fontWidth) |x| {
            const pixelX = cursor.x * font.fontWidth + (font.fontWidth - x - 1);
            const pixelY = cursor.y * font.fontHeight + y;

            const pixelColor = if (fontFile[font.headerSize + char * font.glyphSize + y] & pixelMask == 0) backgroundColor else foregroundColor;
            drawPixel(pixelX, pixelY, pixelColor);

            pixelMask <<= 1;
        }
    }

    cursor.x += 1;

    if (cursor.x >= width / font.fontWidth) {
        cursor.x = 0;
        cursor.y += 1;
    }
}

pub fn putString(string: []const u8) void {
    for (string) |char| {
        putChar(char);
    }
}

pub fn print(comptime format: []const u8, args: anytype) void {
    std.fmt.format(Writer{ .context = {} }, format, args) catch unreachable;
}

pub fn setForegroundColor(color: u32) void {
    foregroundColor = color;
}

pub fn setBackgroundColor(color: u32) void {
    backgroundColor = color;
}

pub fn setCursor(x: u64, y: u64) void {
    cursor.x = x;
    cursor.y = y;
}
