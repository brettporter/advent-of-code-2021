const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

// HELPERS

const LanternFishSimulation = struct {
    initialFish: []const i8,
    currentFish: ArrayList(i8),

    const Self = @This();
    pub fn init(allocator: Allocator, fish: []const i8) !Self {
        var result = Self{
            .initialFish = fish,
            .currentFish = ArrayList(i8).init(allocator),
        };
        try result.reset();
        return result;
    }

    pub fn deinit(self: Self) void {
        self.currentFish.deinit();
    }

    pub fn reset(self: *LanternFishSimulation) !void {
        self.currentFish.clearAndFree();
        try self.currentFish.appendSlice(self.initialFish);
    }

    fn simulateDay(self: *LanternFishSimulation, step: i8) !void {
        var idx: usize = 0;
        const len: usize = self.currentFish.items.len;
        while (idx < len) : (idx += 1) {
            self.currentFish.items[idx] -= step;
            if (self.currentFish.items[idx] < 0) {
                self.currentFish.items[idx] += 7;
                try self.currentFish.append(self.currentFish.items[idx] + 2);
            }
        }
    }

    pub fn simulateDays(self: *LanternFishSimulation, days: i32) !usize {
        var i: i32 = 0;
        while (i < days - 6) : (i += 6) {
            try self.simulateDay(6);
        }
        while (i < days) : (i += 1) {
            try self.simulateDay(1);
        }
        return self.currentFish.items.len;
    }
};

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

    var simulation = try LanternFishSimulation.init(allocator, list.toOwnedSlice());
    print("Day 6: total(80) = {d}\n", .{try simulation.simulateDays(80)});

    try simulation.reset();
    print("Day 6: total(256) = {d}\n", .{try simulation.simulateDays(256)});
}

// TESTING

test "Example" {
    const values = [_]i8{ 3, 4, 3, 1, 2 };
    var simulation = try LanternFishSimulation.init(test_allocator, values[0..]);
    defer simulation.deinit();

    var result = try simulation.simulateDays(18);
    try expect(result == 26);

    try simulation.reset();

    result = try simulation.simulateDays(80);
    try expect(result == 5934);

    try simulation.reset();

    result = try simulation.simulateDays(256);
    try expect(result == 26984457539);
}
