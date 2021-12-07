const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

// HELPERS

var memo: [9][300]u128 = [_][300]u128{[_]u128{0} ** 300} ** 9;

fn simulateSingleLanternFish(fish: u8, days: u32) u128 {
    if (memo[fish][days] > 0) {
        return memo[fish][days];
    }

    const FISH_AGE = 7;

    var newFish: u128 = 0;
    var lifeSpan: u8 = fish;
    var remaining: u32 = days;
    while (remaining > lifeSpan) {
        newFish += 1;

        remaining -= lifeSpan;
        lifeSpan = FISH_AGE;

        newFish += simulateSingleLanternFish(FISH_AGE + 1, remaining - 1);
    }

    memo[fish][days] = newFish;

    return newFish;
}

fn simulateLanternFish(fish: []const u8, days: u32) u128 {
    var count: u128 = 0;
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

    var list = ArrayList(u8).init(allocator);
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
    const values = [_]u8{ 3, 4, 3, 1, 2 };

    var result = simulateLanternFish(values[0..], 18);
    try expect(result == 26);

    result = simulateLanternFish(values[0..], 80);
    try expect(result == 5934);

    result = simulateLanternFish(values[0..], 256);
    try expect(result == 26984457539);
}
