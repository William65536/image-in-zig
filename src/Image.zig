const std = @import("std");

const Self = @This();

const Error = error{
    OutOfBounds,
};

// Uses packed struct because it guarantees ordering of fields
pub const Color = packed struct {
    b: u8,
    g: u8,
    r: u8,
    a: u8 = 0xff,
};

width: usize,
height: usize,
data: []Color,
allocator: std.mem.Allocator,

pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) std.mem.Allocator.Error!Self {
    return .{
        .width = width,
        .height = height,
        .data = try allocator.alloc(Color, width * height),
        .allocator = allocator,
    };
}

pub fn deinit(self: Self) void {
    self.allocator.free(self.data);
}

pub fn clear(self: Self, color: Color) void {
    @memset(self.data, color);
}

pub fn getColor(self: Self, comptime issafe: bool, x: usize, y: usize) if (issafe) error{OutOfBounds}!Color else Color {
    if (issafe and (x >= self.width or y >= self.height)) {
        return Error.OutOfBounds;
    } else {
        std.debug.assert(x < self.width);
        std.debug.assert(y < self.height);
    }

    return self.data[y * self.width + x];
}

pub fn point(self: Self, comptime issafe: bool, x: usize, y: usize, color: Color) if (issafe) error{OutOfBounds}!void else void {
    if (issafe and (x >= self.width or y >= self.height)) {
        return Error.OutOfBounds;
    } else {
        std.debug.assert(x < self.width);
        std.debug.assert(y < self.height);
    }

    self.data[y * self.width + x] = color;
}

pub fn toBMP(self: Self, bmp_writer: anytype) @TypeOf(bmp_writer).Error!void {
    const paddingamount = (4 - self.width * 3 % 4) % 4;
    const headersize = 14;
    const infoheadersize = 40;
    const offsetsize = headersize + infoheadersize;
    const pixelarraysize = self.height * (self.width * 3 + paddingamount);
    const filesize = offsetsize + pixelarraysize;

    const header = [headersize]u8{
        'B', 'M', // File type
        @intCast((filesize >> 8 * 0) & 0xff), @intCast((filesize >> 8 * 1) & 0xff), @intCast((filesize >> 8 * 2) & 0xff), @intCast((filesize >> 8 * 3) & 0xff), // File size
        0, 0, // Reserved 1
        0, 0, // Reserved 2
        @intCast((offsetsize >> 8 * 0) & 0xff), @intCast((offsetsize >> 8 * 1) & 0xff), @intCast((offsetsize >> 8 * 2) & 0xff), @intCast((offsetsize >> 8 * 3) & 0xff), // Pixel data offset
    };

    const infoheader = [infoheadersize]u8{
        @intCast((infoheadersize >> 8 * 0) & 0xff), @intCast((infoheadersize >> 8 * 1) & 0xff), @intCast((infoheadersize >> 8 * 2) & 0xff), @intCast((infoheadersize >> 8 * 3) & 0xff), // Header size
        @intCast((self.width >> 8 * 0) & 0xff), @intCast((self.width >> 8 * 1) & 0xff), @intCast((self.width >> 8 * 2) & 0xff), @intCast((self.width >> 8 * 3) & 0xff), // Image width
        @intCast((self.height >> 8 * 0) & 0xff), @intCast((self.height >> 8 * 1) & 0xff), @intCast((self.height >> 8 * 2) & 0xff), @intCast((self.height >> 8 * 3) & 0xff), // Image height
        1, 0, // Planes
        24, 0, // Bits per pixel
        0, 0, 0, 0, // Compression
        0, 0, 0, 0, // Image size
        0, 0, 0, 0, // X pixels per meter
        0, 0, 0, 0, // Y pixels per meter
        0, 0, 0, 0, // Total colors
        0, 0, 0, 0, // Important colors
    };

    _ = try bmp_writer.write(&header); // TODO: Maybe the size information shouldn't just be thrown out
    _ = try bmp_writer.write(&infoheader);

    const zeros = ([4]u8{ 0, 0, 0, 0 })[0..paddingamount];

    for (0..self.height) |y| {
        for (0..self.width) |x| {
            _ = try bmp_writer.write(@as([*]u8, @ptrCast(&self.data[(self.height - 1 - y) * self.width + x]))[0..3]);
        }

        _ = try bmp_writer.write(zeros);
    }
}
