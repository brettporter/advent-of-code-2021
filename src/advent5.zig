const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
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
                // horizontal
                var direction: i32 = if (l.start.y < l.end.y) 1 else -1;
                var y: i32 = l.start.y;
                while (y != l.end.y + direction) : (y += direction) {
                    self.values[@as(usize, @intCast(l.start.x))][@as(usize, @intCast(y))] += 1;
                }
            } else if (l.start.y == l.end.y) {
                // vertical
                var direction: i32 = if (l.start.x < l.end.x) 1 else -1;
                var x: i32 = l.start.x;
                while (x != l.end.x + direction) : (x += direction) {
                    self.values[@as(usize, @intCast(x))][@as(usize, @intCast(l.start.y))] += 1;
                }
            } else {
                // diagonal
                var directionX: i32 = if (l.start.x < l.end.x) 1 else -1;
                var directionY: i32 = if (l.start.y < l.end.y) 1 else -1;
                var x: i32 = l.start.x;
                var y: i32 = l.start.y;
                while (x != l.end.x + directionX) {
                    self.values[@as(usize, @intCast(x))][@as(usize, @intCast(y))] += 1;
                    x += directionX;
                    y += directionY;
                }
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

    pub fn printMap(self: *const Map, width: i32) void {
        var y: usize = 0;
        while (y < width) : (y += 1) {
            var x: usize = 0;
            while (x < width) : (x += 1) {
                print("{d}", .{self.values[x][y]});
            }
            print("\n", .{});
        }
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

fn parseVentLines(allocator: Allocator, input: [][]const u8, exclude_diagonal: bool) anyerror![]const VentLine {
    var list = ArrayList(VentLine).init(allocator);
    defer list.deinit();
    for (input) |l| {
        var it = std.mem.split(u8, l, " -> ");
        var ventLine = VentLine{
            .start = try readPoint(it.next().?),
            .end = try readPoint(it.next().?),
        };

        if (exclude_diagonal) {
            // currently only consider horizontal and vertical lines
            if (ventLine.start.x != ventLine.end.x and ventLine.start.y != ventLine.end.y) continue;
        }

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
    var ventLines = try parseVentLines(allocator, input, true);

    var map = Map{};
    map.applyVentLines(ventLines);

    print("Day 5 part 1: overlap = {d}\n", .{map.countOverlap()});

    ventLines = try parseVentLines(allocator, input, false);

    map = Map{};
    map.applyVentLines(ventLines);

    print("Day 5 part 2: overlap = {d}\n", .{map.countOverlap()});
}

// TESTING

test "Example" {
    const test_allocator = std.testing.test_allocator;
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

    try expect(map.countOverlap() == 12);
}
