const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

// HELPERS

const MAP_SIZE = 1000;

const Point = struct {
    x: i32,
    y: i32,
};

const VentLine = struct {
    start: Point,
    end: Point,
};

const Map = struct {
    values: [MAP_SIZE][MAP_SIZE]i8 = [_][MAP_SIZE]i8{[_]i8{0} ** MAP_SIZE} ** MAP_SIZE,

    pub fn applyVentLines(self: *Map, lines: []const VentLine) void {
        for (lines) |l| {
            if (l.start.x == l.end.x) {
                // horizontal - start at smallest number
                var y: i32 = std.math.min(l.start.y, l.end.y);
                var end: i32 = std.math.max(l.start.y, l.end.y);
                while (y <= end) : (y += 1) {
                    self.values[@intCast(usize, l.start.x)][@intCast(usize, y)] += 1;
                }
            } else if (l.start.y == l.end.y) {
                // vertical - start at smallest number
                var x: i32 = std.math.min(l.start.x, l.end.x);
                var end: i32 = std.math.max(l.start.x, l.end.x);
                while (x <= end) : (x += 1) {
                    self.values[@intCast(usize, x)][@intCast(usize, l.start.y)] += 1;
                }
            } else {
                unreachable();
            }
        }
    }

    pub fn countOverlap(self: *const Map) i32 {
        var count: i32 = 0;
        for (self.values) |col| {
            for (col) |v| {
                if (v >= 2) {
                    count += 1;
                }
            }
        }
        return count;
    }
};

fn readPoint(str: []const u8) anyerror!Point {
    var it = std.mem.split(u8, str, ",");
    var p = Point{
        .x = try std.fmt.parseInt(i32, it.next().?, 10),
        .y = try std.fmt.parseInt(i32, it.next().?, 10),
    };
    if (p.x >= 1000) {
        return error.InvalidData;
    }
    if (p.y >= 1000) {
        return error.InvalidData;
    }
    return p;
}

fn parseVentLines(allocator: Allocator, input: [][]const u8) anyerror![]const VentLine {
    var list = ArrayList(VentLine).init(allocator);
    defer list.deinit();
    for (input) |l| {
        var it = std.mem.split(u8, l, " -> ");
        var ventLine = VentLine{
            .start = try readPoint(it.next().?),
            .end = try readPoint(it.next().?),
        };

        // currently only consider horizontal and vertical lines
        if (ventLine.start.x != ventLine.end.x and ventLine.start.y != ventLine.end.y) continue;

        try list.append(ventLine);
    }
    return list.toOwnedSlice();
}

// MAIN

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var input = try common.readFile(allocator, "data/day5input.txt");
    var ventLines = try parseVentLines(allocator, input);

    var map = Map{};
    map.applyVentLines(ventLines);

    print("Day 4: overlap = {d}\n", .{map.countOverlap()});
}

// TESTING

test "Example" {
    const input = try common.readInput(test_allocator,
        \\0,9 -> 5,9
        \\8,0 -> 0,8
        \\9,4 -> 3,4
        \\2,2 -> 2,1
        \\7,0 -> 7,4
        \\6,4 -> 2,0
        \\0,9 -> 2,9
        \\3,4 -> 1,4
        \\0,0 -> 8,8
        \\5,5 -> 8,2
    );
    defer {
        for (input) |i| test_allocator.free(i);
        test_allocator.free(input);
    }

    var ventLines = try parseVentLines(test_allocator, input);
    defer test_allocator.free(ventLines);

    var map = Map{};
    map.applyVentLines(ventLines);

    try expect(map.countOverlap() == 5);
}
