const std = @import("std");
const Image = @import("Image.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const image = try Image.init(1280, 720, allocator);
    defer image.deinit();

    image.clear(.{ .r = 0x00, .g = 0x00, .b = 0xff });

    // Draw circle
    {
        var x: isize = 0;
        var y: isize = 0;

        while (x <= 200) : (x += 1) {
            while (y <= 200) : (y += 1) {
                if ((x - 100) * (x - 100) + (y - 100) * (y - 100) <= 100 * 100) {
                    image.point(false, @intCast(x + 100), @intCast(y + 100), .{ .r = 0x00, .g = 0xff, .b = 0x00 });
                }
            }

            y = 0;
        }
    }

    const bmp_file = try std.fs.cwd().createFile("test.bmp", .{ .truncate = true });
    defer bmp_file.close();

    var buf = std.io.bufferedWriter(bmp_file.writer());
    defer buf.flush() catch unreachable;

    const bmp_writer = buf.writer();

    try image.toBMP(bmp_writer);
}
