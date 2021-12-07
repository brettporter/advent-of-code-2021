const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

// HELPERS

const CrabFormation = struct {
    position: i32,
    movementTotal: i32,
};

fn calculateCost(values: []const i32, target: i32) i32 {
    var cost: i32 = 0;
    for (values) |v| {
        cost += std.math.absInt(v - target) catch unreachable();
    }
    return cost;
}

fn findEfficientCrabFormation(values: []const i32) CrabFormation {
    var max: i32 = 0;
    for (values) |v| {
        if (v > max) max = v;
    }

    var minCost = max * @intCast(i32, values.len);
    var position: i32 = -1;
    var i: i32 = 0;
    while (i < max) : (i += 1) {
        var cost = calculateCost(values, i);
        if (cost < minCost) {
            minCost = cost;
            position = i;
        }
    }
    return CrabFormation{
        .position = position,
        .movementTotal = minCost,
    };
}

// MAIN

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var input = try common.readFileCommaSepInt(allocator, "data/day7input.txt");

    var result = findEfficientCrabFormation(input);
    print("Day 7: position = {d}, cost = {d}\n", .{ result.position, result.movementTotal });
}

// TESTING

test "Example" {
    const values = [_]i32{ 16, 1, 2, 0, 4, 2, 7, 1, 2, 14 };
    const input = values[0..];

    const result = findEfficientCrabFormation(input);
    try expect(result.position == 2);
    try expect(result.movementTotal == 37);
}

test "Calculate Fuel" {
    const values = [_]i32{ 16, 1, 2, 0, 4, 2, 7, 1, 2, 14 };
    const input = values[0..];

    try expect(calculateCost(input, 2) == 37);
    try expect(calculateCost(input, 1) == 41);
    try expect(calculateCost(input, 3) == 39);
    try expect(calculateCost(input, 10) == 71);
}
