const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

// HELPERS

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

// MAIN

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var input = try common.readFile(allocator, "data/day8input.txt");
    print("Day 8: unique = {d}\n", .{countUniqueOutput(input)});
}

// TESTING

test "Example" {
    const input = try common.readInput(test_allocator,
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
    );
    defer {
        for (input) |i| test_allocator.free(i);
        test_allocator.free(input);
    }

    try expect(countUniqueOutput(input) == 26);
}
