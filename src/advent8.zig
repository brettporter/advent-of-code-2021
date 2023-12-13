const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const print = std.debug.print;

// HELPERS

const SIGNAL_LOOKUP = [_]u8{ 0b1110111, 0b0010010, 0b1011101, 0b1011011, 0b0111010, 0b1101011, 0b1101111, 0b1010010, 0b1111111, 0b1111011 };

fn computeAnswer(allocator: Allocator, input: [][]const u8) !i32 {
    var result: i32 = 0;
    for (input) |line| {
        result += try computeDigits(allocator, line);
    }
    return result;
}

fn computeDigits(allocator: Allocator, line: []const u8) !i32 {
    var iter = std.mem.tokenize(u8, line, "|");
    var inputData = iter.next().?;
    var outputData = iter.next().?;

    var signals = ArrayList([]const u8).init(allocator);
    defer signals.deinit();
    var it1 = std.mem.split(u8, inputData, " ");
    while (it1.next()) |v| {
        if (v.len > 0) try signals.append(v);
    }

    var mapping: [7]u8 = [_]u8{0} ** 7;
    try mapSignals(allocator, signals.items, &mapping);

    var invertedMapping: [7]u8 = undefined;
    for (mapping, 0..) |m, idx| {
        invertedMapping[m - 'a'] = @as(u8, @intCast(idx));
    }

    var result: i32 = 0;
    var it2 = std.mem.split(u8, outputData, " ");
    while (it2.next()) |v| {
        var value: i32 = 0;
        for (v) |c| {
            var idx: u3 = @as(u3, @intCast(6 - (invertedMapping[c - 'a'])));
            value += @as(u8, 1) << idx;
        }
        for (SIGNAL_LOOKUP, 0..) |l, idx| {
            if (l == value) {
                result = result * 10 + @as(i32, @intCast(idx));
                break;
            }
        }
    }
    return result;
}

fn countUniqueOutput(input: [][]const u8) i32 {
    var count: i32 = 0;
    for (input) |l| {
        var iter = std.mem.tokenize(u8, l, "|");
        // skip input data
        _ = iter.next().?;
        var outputData = iter.next().?;

        var it = std.mem.split(u8, outputData, " ");
        while (it.next()) |v| {
            // count output lengths of 2 (for 1), 4 (for 4), 3 (for 7), 7 (for 8)
            if (v.len == 2 or v.len == 3 or v.len == 4 or v.len == 7) {
                count += 1;
            }
        }
    }
    return count;
}

fn uniqueSignal(a: []const u8, b: []const u8) !u8 {
    for (a) |c| {
        var found: bool = false;
        for (b) |d| {
            if (c == d) {
                found = true;
                break;
            }
        }
        if (!found) {
            return c;
        }
    }
    return error.InvalidData;
}

fn commonSignal(items: []const []const u8) ![4]u8 {
    var result: [4]u8 = [_]u8{0} ** 4;
    var segments: [7]u4 = [_]u4{0} ** 7;
    for (items) |i| {
        for (i) |c| {
            segments[c - 'a'] += 1;
        }
    }
    var ridx: u4 = 0;
    for (segments, 0..) |s, idx| {
        if (s == items.len) {
            if (ridx == 4) {
                return error.InvalidData;
            }
            result[ridx] = @as(u8, @intCast(idx)) + 'a';
            ridx += 1;
        }
    }
    return result;
}

fn mapSignals(allocator: Allocator, signals: []const []const u8, output: *[7]u8) !void {
    var candidateFor235 = ArrayList([]const u8).init(allocator);
    defer candidateFor235.deinit();
    var candidateFor069 = ArrayList([]const u8).init(allocator);
    defer candidateFor069.deinit();
    var digits: [10][]const u8 = undefined;
    for (signals) |s| {
        switch (s.len) {
            2 => digits[1] = s,
            3 => digits[7] = s,
            4 => digits[4] = s,
            7 => digits[8] = s,
            5 => try candidateFor235.append(s),
            6 => try candidateFor069.append(s),
            else => return error.InvalidData,
        }
    }

    //   s0s0
    // s1    s2
    // s1    s2
    //   s3s3
    // s4    s5
    // s4    s5
    //   s6s6

    // s0 is the letter in 7 and not in 1
    output[0] = try uniqueSignal(digits[7], digits[1]);

    // s3 is the letter in 3 and 6 and 4
    var pair36 = try commonSignal(candidateFor235.items);
    output[3] = (try commonSignal(&[_][]const u8{ pair36[0..3], digits[4] }))[0];

    // s6 is the letter in 3 and 6 that is not the above rows
    for (pair36) |c| {
        if (c != output[0] and c != output[3]) {
            output[6] = c;
            break;
        }
    }

    // s1 is the letter in 4 and not in 3
    var n3 = [_]u8{ output[0], output[3], output[6], digits[1][0], digits[1][1] };
    output[1] = try uniqueSignal(digits[4], &n3);

    // s2 is the letter in 1 and not in 0, 6, 9
    var common069 = try commonSignal(candidateFor069.items);
    output[2] = try uniqueSignal(digits[1], &common069);

    // s5 is the letter in 1 that is not s2
    for (digits[1]) |c| {
        if (c != output[2]) output[5] = c;
    }

    // s4 is the last one left
    output[4] = try uniqueSignal(digits[8], output);
}

// MAIN

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var input = try common.readFile(allocator, "data/day8input.txt");
    print("Day 8: unique = {d}\n", .{countUniqueOutput(input)});
    print("Day 8: total = {!d}\n", .{computeAnswer(allocator, input)});
}

// TESTING

const SINGLE_EXAMPLE =
    \\acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf
;

const LONG_EXAMPLE =
    \\be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
    \\edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
    \\fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
    \\fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
    \\aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
    \\fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
    \\dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
    \\bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
    \\egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
    \\gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
;

test "Example Unique Output" {
    const test_allocator = std.testing.test_allocator;
    const input = try common.readInput(test_allocator, LONG_EXAMPLE);
    defer {
        for (input) |i| test_allocator.free(i);
        test_allocator.free(input);
    }

    try expect(countUniqueOutput(input) == 26);
}

test "Unique Signal" {
    var result = try uniqueSignal("dabe", "bed");
    try expect(result == 'a');
}

test "Mapping Signal Lines" {
    const test_allocator = std.testing.test_allocator;
    const signals = [_][]const u8{ "acedgfb", "cdfbe", "gcdfa", "fbcad", "dab", "cefabd", "cdfgeb", "eafb", "cagedb", "ab" };

    var mapping: [7]u8 = [_]u8{0} ** 7;
    try mapSignals(test_allocator, signals[0..], &mapping);

    try expect(mapping[0] == 'd'); // a -> d
    try expect(mapping[1] == 'e'); // b -> e
    try expect(mapping[2] == 'a'); // c -> a
    try expect(mapping[3] == 'f'); // d -> f
    try expect(mapping[4] == 'g'); // e -> g
    try expect(mapping[5] == 'b'); // f -> b
    try expect(mapping[6] == 'c'); // g -> c
}

test "Single Example Answer" {
    const test_allocator = std.testing.test_allocator;
    const input = try common.readInput(test_allocator, SINGLE_EXAMPLE);
    defer {
        for (input) |i| test_allocator.free(i);
        test_allocator.free(input);
    }

    var result = try computeDigits(test_allocator, input[0]);
    try expect(result == 5353);
}

test "Long Example Answer" {
    const test_allocator = std.testing.test_allocator;
    const input = try common.readInput(test_allocator, LONG_EXAMPLE);
    defer {
        for (input) |i| test_allocator.free(i);
        test_allocator.free(input);
    }

    var result = try computeAnswer(test_allocator, input);
    try expect(result == 61229);
}
