const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

// HELPERS

fn calculateRisk(input: [][]const u8) i32 {
    var risk: i32 = 0;
    for (input) |row, ridx| {
        for (row) |col, cidx| {
            // left
            if (cidx > 0 and row[cidx - 1] <= col) continue;
            // right
            if (cidx < row.len - 1 and row[cidx + 1] <= col) continue;
            // up
            if (ridx > 0 and input[ridx - 1][cidx] <= col) continue;
            // down
            if (ridx < input.len - 1 and input[ridx + 1][cidx] <= col) continue;

            risk += (col - '0' + 1);
        }
    }
    return risk;
}

// MAIN

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var input = try common.readFile(allocator, "data/day9input.txt");
    print("Day 9: risk = {d}\n", .{calculateRisk(input)});
}

// TESTING

const EXAMPLE =
    \\2199943210
    \\3987894921
    \\9856789892
    \\8767896789
    \\9899965678
;

test "Example" {
    const input = try common.readInput(test_allocator, EXAMPLE);
    defer {
        for (input) |i| test_allocator.free(i);
        test_allocator.free(input);
    }

    var result = calculateRisk(input);
    try expect(result == 15);
}

test "Equal pair" {
    const input = try common.readInput(test_allocator,
        \\499
        \\989
    );
    defer {
        for (input) |i| test_allocator.free(i);
        test_allocator.free(input);
    }

    var result = calculateRisk(input);
    try expect(result == 14);
}
