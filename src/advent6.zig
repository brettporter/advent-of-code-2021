const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const print = std.debug.print;

// HELPERS

var memo: [9][300]u128 = [_][300]u128{[_]u128{0} ** 300} ** 9;

fn simulateSingleLanternFish(fish: u16, days: u32) u128 {
    if (memo[fish][days] > 0) {
        return memo[fish][days];
    }

    const FISH_AGE = 7;

    var newFish: u128 = 0;
    var lifeSpan: u16 = fish;
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

fn simulateLanternFish(fish: []const i32, days: u32) u128 {
    var count: u128 = 0;
    for (fish) |f| {
        count += 1;
        count += simulateSingleLanternFish(@as(u16, @intCast(f)), days);
    }
    return count;
}

// MAIN

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const fish = try common.readFileCommaSepInt(allocator, "data/day6input.txt");
    print("Day 6: total(80) = {d}\n", .{simulateLanternFish(fish, 80)});
    print("Day 6: total(256) = {d}\n", .{simulateLanternFish(fish, 256)});
}

// TESTING

test "Example" {
    const values = [_]i32{ 3, 4, 3, 1, 2 };

    var result = simulateLanternFish(values[0..], 18);
    try expect(result == 26);

    result = simulateLanternFish(values[0..], 80);
    try expect(result == 5934);

    result = simulateLanternFish(values[0..], 256);
    try expect(result == 26984457539);
}
