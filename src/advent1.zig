const std = @import("std");
const ArrayList = std.ArrayList;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

fn measureIncreases(depths: []const usize) usize {
    var count: usize = 0;
    var previous: usize = undefined;
    for (depths) |v| {
        if (v > previous) count += 1;
        previous = v;
    }
    return count;
}

fn measureSlidingIncreases(depths: []const usize) usize {
    var count: usize = 0;
    var previous: usize = undefined;
    for (depths) |_, index| {
        var sum: usize = 0;
        var end = if (index < depths.len - 3) index + 3 else depths.len;
        for (depths[index..end]) |v| sum += v;

        if (sum > previous) count += 1;
        previous = sum;
    }
    return count;
}

pub fn main() anyerror!void {
    var list = try common.readFile(test_allocator, "data/day1input.txt");
    defer test_allocator.free(list);

    var depths = ArrayList(usize).init(test_allocator);
    defer depths.deinit();

    for (list) |line| {
        try depths.append(try std.fmt.parseInt(usize, line, 10));
    }

    print("Day 1: {d}, {d}\n", .{ measureIncreases(depths.items), measureSlidingIncreases(depths.items) });
}

test "Example depths" {
    const values = [_]usize{ 199, 200, 208, 210, 200, 207, 240, 269, 260, 263 };
    var increases = measureIncreases(values[0..]);
    try expect(increases == 7);

    var slidingIncreases = measureSlidingIncreases(values[0..]);
    try expect(slidingIncreases == 5);
}
