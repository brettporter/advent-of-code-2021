const std = @import("std");
const ArrayList = std.ArrayList;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

const Diagnostic = struct {
    gamma: i32,
    epsilon: i32,
    oxygen: i32,
    co2scrubber: i32,

    fn powerConsumption(self: *Diagnostic) i32 {
        return self.gamma * self.epsilon;
    }

    fn lifeSupportRating(self: *Diagnostic) i32 {
        return self.oxygen * self.co2scrubber;
    }
};

fn bitCriteria(idx: usize, values: []const []const u8) anyerror!u1 {
    var sum: usize = 0;
    for (values) |d| {
        switch (d[idx]) {
            '1' => sum += 1,
            '0' => {},
            else => {
                return error.InvalidCharacter;
            },
        }
    }

    const count = std.mem.len(values);
    if (sum * 2 >= count) {
        // if the total is greater than half, then 1 is the most common value, add it to gamma at this bit position
        // if exactly half, then we use 1 per rules of part 2
        // use multiplication to avoid rounding error if count is odd
        return 1;
    }
    return 0;
}

fn filterDiagnostics(diagnostics: []const []const u8, idx: usize, wantMatch: bool) anyerror!i32 {
    var list = ArrayList([]const u8).init(test_allocator);
    defer list.deinit();

    var c = try bitCriteria(idx, diagnostics);

    for (diagnostics) |d| {
        // check if the bit at this index matches the criteria
        var matches = (d[idx] - '0' == c);
        if (matches == wantMatch) {
            try list.append(d);
        }
    }
    if (list.items.len == 1) {
        return try std.fmt.parseInt(i32, list.items[0], 2);
    }
    if (list.items.len == 0) {
        return error.InvalidData;
    }
    return try filterDiagnostics(list.items, idx + 1, wantMatch);
}

fn readDiagnostics(diagnostics: []const []const u8) anyerror!Diagnostic {
    const expectedLength = std.mem.len(diagnostics[0]);
    if (expectedLength > 31) {
        // Only support 31 bits for u5 below
        return error.SizeError;
    }
    for (diagnostics) |d| {
        if (std.mem.len(d) != expectedLength) {
            return error.SizeError;
        }
    }

    var gamma: i32 = 0;
    var i: usize = 0;
    while (i < expectedLength) : (i += 1) {
        var c = try bitCriteria(i, diagnostics);
        if (c == 1) gamma += @as(i32, 1) << @intCast(u5, expectedLength - i - 1);
    }

    // flip bits of gamma to get epsilon since the answer is always opposite (we could also just subtract...)
    const epsilon = gamma ^ ((@as(i32, 1) << @intCast(u5, expectedLength)) - 1);

    const oxygen = try filterDiagnostics(diagnostics, 0, true);
    const co2scrubber = try filterDiagnostics(diagnostics, 0, false);

    return Diagnostic{ .gamma = gamma, .epsilon = epsilon, .oxygen = oxygen, .co2scrubber = co2scrubber };
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = try common.readFile(allocator, "data/day3input.txt");

    var result = try readDiagnostics(list);

    print("Day 3: gamma = {d}, epsilon = {d}, power = {d}\n", .{ result.gamma, result.epsilon, result.powerConsumption() });
    print("Day 3: oxygen = {d}, co2scrubber = {d}, lifeSupportRating = {d}\n", .{ result.oxygen, result.co2scrubber, result.lifeSupportRating() });
}

test "Example" {
    const values = [_][]const u8{ "00100", "11110", "10110", "10111", "10101", "01111", "00111", "11100", "10000", "11001", "00010", "01010" };

    var result = try readDiagnostics(values[0..]);

    try expect(result.gamma == 22);
    try expect(result.epsilon == 9);
    try expect(result.powerConsumption() == 198);

    try expect(result.oxygen == 23);
    try expect(result.co2scrubber == 10);
    try expect(result.lifeSupportRating() == 230);
}

test "Odd length" {
    const values = [_][]const u8{ "00100", "11110", "10110" };

    var result = try readDiagnostics(values[0..]);

    try expect(result.gamma == 22); // 0b10110
    try expect(result.epsilon == 9); // 0b01001
    try expect(result.powerConsumption() == 198);
}

test "Undefined result in part 1" {
    const values = [_][]const u8{ "00100", "11110", "10110", "01111" };

    var result = try readDiagnostics(values[0..]);

    try expect(result.gamma == 30); // 0b11110
    try expect(result.epsilon == 1); // 0b00001
    try expect(result.powerConsumption() == 30);
}

test "Invalid input" {
    const values = [_][]const u8{ "00100", "111", "10110" };
    try std.testing.expectError(error.SizeError, readDiagnostics(values[0..]));

    const values2 = [_][]const u8{"010101010101010101010101010101011"};
    try std.testing.expectError(error.SizeError, readDiagnostics(values2[0..]));

    const values3 = [_][]const u8{"12345"};
    try std.testing.expectError(error.InvalidCharacter, readDiagnostics(values3[0..]));
}
