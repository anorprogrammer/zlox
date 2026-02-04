const std = @import("std");

pub fn main() !void {
    const lang = "Zlox";
    std.debug.print("Hello, {s}", .{lang});
}
