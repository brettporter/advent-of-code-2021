const std = @import("std");
const ArrayList = std.ArrayList;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

const PowerConsumption = struct {
    gamma: i32,
    epsilon: i32,

    fn value(self: *PowerConsumption) i32 {
        return self.gamma * self.epsilon;
    }
};

fn readDiagnostics(diagnostics: []const []const u8) anyerror!PowerConsumption {
    const MAX_LENGTH = 31;
    var bitSum = [_]usize{0} ** MAX_LENGTH;

    const expectedLength = std.mem.len(diagnostics[0]);
    if (expectedLength > MAX_LENGTH) {
        return error.SizeError;
    }

    for (diagnostics) |d| {
        if (std.mem.len(d) != expectedLength) {
            return error.SizeError;
        }
        for (d) |b, idx| {
            switch (b) {
                '1' => bitSum[idx] += 1,
                '0' => {},
                else => {
                    return error.InvalidCharacter;
                },
            }
        }
    }

    const count = std.mem.len(diagnostics);
    var gamma: i32 = 0;
    for (bitSum) |v, idx| {
        if (idx >= expectedLength) break;

        if (v > count / 2) {
            // if the total is greater than half, then 1 is the most common value, add it to gamma at this bit position
            gamma += @as(i32, 1) << @intCast(u5, expectedLength - idx - 1);
        } else if (v * 2 == count) {
            // if exactly half, then we don't know what to set it to
            // use multiplication to avoid rounding error if count is odd
            return error.UndefinedResult;
        }
    }

    // flip bits of gamma to get epsilon since the answer is always opposite (we could also just subtract...)
    const epsilon = gamma ^ ((@as(i32, 1) << @intCast(u5, expectedLength)) - 1);

    return PowerConsumption{ .gamma = gamma, .epsilon = epsilon };
}

pub fn main() anyerror!void {
    var list = try common.readFile(test_allocator, "data/day3input.txt");
    defer test_allocator.free(list);

    var result = try readDiagnostics(list);

    print("Day 3: gamma = {d}, epsilon = {d}, answer = {d}\n", .{ result.gamma, result.epsilon, result.value() });
}

test "Example" {
    const values = [_][]const u8{ "00100", "11110", "10110", "10111", "10101", "01111", "00111", "11100", "10000", "11001", "00010", "01010" };

    var result = try readDiagnostics(values[0..]);

    try expect(result.gamma == 22);
    try expect(result.epsilon == 9);
    try expect(result.value() == 198);
}

test "Odd length" {
    const values = [_][]const u8{ "00100", "11110", "10110" };

    var result = try readDiagnostics(values[0..]);

    try expect(result.gamma == 22); // 0b10110
    try expect(result.epsilon == 9); // 0b01001
    try expect(result.value() == 198);
}

test "Undefined result" {
    const values = [_][]const u8{ "00100", "11110", "10110", "01111" };

    try std.testing.expectError(error.UndefinedResult, readDiagnostics(values[0..]));
}

test "Invalid input" {
    const values = [_][]const u8{ "00100", "111", "10110" };
    try std.testing.expectError(error.SizeError, readDiagnostics(values[0..]));

    const values2 = [_][]const u8{"010101010101010101010101010101011"};
    try std.testing.expectError(error.SizeError, readDiagnostics(values2[0..]));

    const values3 = [_][]const u8{"12345"};
    try std.testing.expectError(error.InvalidCharacter, readDiagnostics(values3[0..]));
}
