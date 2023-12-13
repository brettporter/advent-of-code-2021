const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const print = std.debug.print;

// HELPERS

const Point = struct {
    row: usize,
    col: usize,
    value: i32 = 0,
};

fn findLowPoints(allocator: Allocator, input: [][]const u8) ![]Point {
    var lowPoints = ArrayList(Point).init(allocator);
    for (input, 0..) |row, ridx| {
        for (row, 0..) |col, cidx| {
            // left
            if (cidx > 0 and row[cidx - 1] <= col) continue;
            // right
            if (cidx < row.len - 1 and row[cidx + 1] <= col) continue;
            // up
            if (ridx > 0 and input[ridx - 1][cidx] <= col) continue;
            // down
            if (ridx < input.len - 1 and input[ridx + 1][cidx] <= col) continue;

            try lowPoints.append(Point{ .row = ridx, .col = cidx, .value = col - '0' });
        }
    }
    return lowPoints.toOwnedSlice();
}

fn calculateRisk(lowPoints: []Point) i32 {
    var risk: i32 = 0;
    for (lowPoints) |p| {
        risk += (p.value + 1);
    }
    return risk;
}

fn traverseBasin(input: [][]const u8, seen: []bool, point: Point) i32 {
    // check and set seen
    var sidx: usize = point.row * input[0].len + point.col;
    if (seen[sidx]) return 0;
    seen[sidx] = true;

    var result: i32 = 1;

    // left
    if (point.col > 0 and input[point.row][point.col - 1] != '9') {
        result += traverseBasin(input, seen, Point{ .row = point.row, .col = point.col - 1 });
    }
    // right
    if (point.col < input[point.row].len - 1 and input[point.row][point.col + 1] != '9') {
        result += traverseBasin(input, seen, Point{ .row = point.row, .col = point.col + 1 });
    }
    // up
    if (point.row > 0 and input[point.row - 1][point.col] != '9') {
        result += traverseBasin(input, seen, Point{ .row = point.row - 1, .col = point.col });
    }
    // down
    if (point.row < input.len - 1 and input[point.row + 1][point.col] != '9') {
        result += traverseBasin(input, seen, Point{ .row = point.row + 1, .col = point.col });
    }
    return result;
}

fn findThreeLargestBasins(allocator: Allocator, input: [][]const u8, lowPoints: []Point) !i32 {
    var seen = try allocator.alloc(bool, input.len * input[0].len);
    var basinSizes = ArrayList(i32).init(allocator);
    defer {
        basinSizes.deinit();
        allocator.free(seen);
    }

    for (lowPoints) |p| {
        try basinSizes.append(traverseBasin(input, seen, p));
    }

    std.mem.sort(i32, basinSizes.items, {}, comptime std.sort.desc(i32));

    var totalSize: i32 = 1;
    for (basinSizes.items[0..3]) |i| {
        totalSize *= i;
    }
    return totalSize;
}

// MAIN

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var input = try common.readFile(allocator, "data/day9input.txt");
    var lowPoints = try findLowPoints(allocator, input);
    print("Day 9: risk = {d}\n", .{calculateRisk(lowPoints)});
    print("Day 9: largest basins = {!d}\n", .{findThreeLargestBasins(allocator, input, lowPoints)});
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
    const test_allocator = std.testing.test_allocator;
    const input = try common.readInput(test_allocator, EXAMPLE);
    defer {
        for (input) |i| test_allocator.free(i);
        test_allocator.free(input);
    }

    var lowPoints = try findLowPoints(test_allocator, input);
    defer test_allocator.free(lowPoints);
    var result = calculateRisk(lowPoints);
    try expect(result == 15);

    var result2 = try findThreeLargestBasins(test_allocator, input, lowPoints);
    try expect(result2 == 1134);
}

test "Equal pair" {
    const test_allocator = std.testing.test_allocator;
    const input = try common.readInput(test_allocator,
        \\499
        \\989
    );
    defer {
        for (input) |i| test_allocator.free(i);
        test_allocator.free(input);
    }

    var lowPoints = try findLowPoints(test_allocator, input);
    defer test_allocator.free(lowPoints);
    var result = calculateRisk(lowPoints);
    try expect(result == 14);
}
