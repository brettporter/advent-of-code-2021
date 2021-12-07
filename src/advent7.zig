const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

// HELPERS

const CrabMovement = enum {
    basic,
    advanced,

    pub fn calculate(self: CrabMovement, distance: i32) i32 {
        return switch (self) {
            .basic => distance,
            .advanced => @divExact(distance * (distance + 1), 2),
        };
    }
};

const CrabFormation = struct {
    position: i32,
    movementTotal: i32,
};

fn calculateCost(movement: CrabMovement, values: []const i32, target: i32) i32 {
    var cost: i32 = 0;
    for (values) |v| {
        const distance = std.math.absInt(v - target) catch unreachable();
        cost += movement.calculate(distance);
    }
    return cost;
}

fn findEfficientCrabFormation(movement: CrabMovement, values: []const i32) CrabFormation {
    var max: i32 = 0;
    for (values) |v| {
        if (v > max) max = v;
    }

    var minCost: i32 = -1;
    var position: i32 = -1;
    var i: i32 = 0;
    while (i < max) : (i += 1) {
        var cost = calculateCost(movement, values, i);
        if (minCost == -1 or cost < minCost) {
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

    var result = findEfficientCrabFormation(CrabMovement.basic, input);
    print("Day 7: position = {d}, cost = {d}\n", .{ result.position, result.movementTotal });

    result = findEfficientCrabFormation(CrabMovement.advanced, input);
    print("Day 7 part 2: position = {d}, cost = {d}\n", .{ result.position, result.movementTotal });
}

// TESTING

const EXAMPLE_VALUES = [_]i32{ 16, 1, 2, 0, 4, 2, 7, 1, 2, 14 };

test "Example" {
    const input = EXAMPLE_VALUES[0..];

    const result = findEfficientCrabFormation(CrabMovement.basic, input);
    try expect(result.position == 2);
    try expect(result.movementTotal == 37);
}

test "Example Part 2" {
    const input = EXAMPLE_VALUES[0..];

    const result = findEfficientCrabFormation(CrabMovement.advanced, input);
    try expect(result.position == 5);
    try expect(result.movementTotal == 168);
}

test "Calculate Fuel" {
    const input = EXAMPLE_VALUES[0..];

    try expect(calculateCost(CrabMovement.basic, input, 2) == 37);
    try expect(calculateCost(CrabMovement.basic, input, 1) == 41);
    try expect(calculateCost(CrabMovement.basic, input, 3) == 39);
    try expect(calculateCost(CrabMovement.basic, input, 10) == 71);

    try expect(calculateCost(CrabMovement.advanced, input, 5) == 168);
    try expect(calculateCost(CrabMovement.advanced, input, 2) == 206);
}
