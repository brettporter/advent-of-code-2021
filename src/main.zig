const std = @import("std");

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});

    try @import("advent1.zig").main();
    try @import("advent2.zig").main();
    try @import("advent3.zig").main();
    try @import("advent4.zig").main();
    try @import("advent5.zig").main();
    try @import("advent6.zig").main();
    try @import("advent7.zig").main();
    try @import("advent8.zig").main();
    try @import("advent9.zig").main();
    try @import("advent10.zig").main();
    try @import("advent11.zig").main();
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
