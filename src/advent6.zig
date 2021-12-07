const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

// HELPERS

fn simulateSingleLanternFish(fish: i8, days: i32) i128 {
    const FISH_AGE = 7;

    var newFish: i128 = 0;
    var lifeSpan: i8 = fish;
    var remaining: i32 = days;
    while (remaining > lifeSpan) {
        newFish += 1;

        remaining -= lifeSpan;
        lifeSpan = FISH_AGE;

        newFish += simulateSingleLanternFish(FISH_AGE + 1, remaining - 1);
    }
    return newFish;
}

fn simulateLanternFish(fish: []const i8, days: i32) i128 {
    var count: i128 = 0;
    for (fish) |f, idx| {
        count += 1;
        count += simulateSingleLanternFish(f, days);

        print("{d}/{d}\t{d}\n", .{ idx, fish.len, count });
    }
    return count;
}

// MAIN

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var input = try common.readFile(allocator, "data/day6input.txt");

    var list = ArrayList(i8).init(allocator);
    var iter = std.mem.split(u8, input[0], ",");
    while (iter.next()) |n| {
        try list.append(try std.fmt.parseInt(u4, n, 10));
    }

    const fish = list.toOwnedSlice();
    print("Day 6: total(80) = {d}\n", .{simulateLanternFish(fish, 80)});
    print("Day 6: total(256) = {d}\n", .{simulateLanternFish(fish, 256)});
}

// TESTING

test "Example" {
    const values = [_]i8{ 3, 4, 3, 1, 2 };

    var result = simulateLanternFish(values[0..], 18);
    try expect(result == 26);

    result = simulateLanternFish(values[0..], 80);
    try expect(result == 5934);

    result = simulateLanternFish(values[0..], 256);
    try expect(result == 26984457539);
}
