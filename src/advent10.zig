const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

// HELPERS

const SCORE_OK: i32 = 0;
const SCORE_RIGHT_PAREN: i32 = 3;
const SCORE_RIGHT_BRACKET: i32 = 57;
const SCORE_RIGHT_BRACE: i32 = 1197;
const SCORE_GT: i32 = 25137;

fn checkChunkCorruption(allocator: Allocator, input: []const u8) !i32 {
    const L = std.SinglyLinkedList(u8);
    var pairs = L{};
    defer {
        while (pairs.popFirst()) |node| {
            allocator.destroy(node);
        }
    }

    for (input) |c| {
        switch (c) {
            '(', '[', '{', '<' => {
                var n = try allocator.create(L.Node);
                n.data = c;
                pairs.prepend(n);
            },
            ')' => {
                var n = pairs.popFirst().?;
                defer allocator.destroy(n);
                if (n.data != '(') return SCORE_RIGHT_PAREN;
            },
            ']' => {
                var n = pairs.popFirst().?;
                defer allocator.destroy(n);
                if (n.data != '[') return SCORE_RIGHT_BRACKET;
            },
            '}' => {
                var n = pairs.popFirst().?;
                defer allocator.destroy(n);
                if (n.data != '{') return SCORE_RIGHT_BRACE;
            },
            '>' => {
                var n = pairs.popFirst().?;
                defer allocator.destroy(n);
                if (n.data != '<') return SCORE_GT;
            },
            else => return error.InvalidData,
        }
    }
    return SCORE_OK;
}

fn calculateSyntaxError(allocator: Allocator, input: [][]const u8) !i32 {
    var total: i32 = 0;
    for (input) |l| {
        total += try checkChunkCorruption(allocator, l);
    }
    return total;
}

// MAIN

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var input = try common.readFile(allocator, "data/day10input.txt");
    print("Day 10: syntax error = {d}\n", .{calculateSyntaxError(allocator, input)});
}

// TESTING

const EXAMPLE =
    \\[({(<(())[]>[[{[]{<()<>>
    \\[(()[<>])]({[<{<<[]>>(
    \\{([(<{}[<>[]}>{[]{[(<()>
    \\(((({<>}<{<{<>}{[]{[]{}
    \\[[<[([]))<([[{}[[()]]]
    \\[{[{({}]{}}([{[{{{}}([]
    \\{<[[]]>}<{[{[{[]{()[[[]
    \\[<(<(<(<{}))><([]([]()
    \\<{([([[(<>()){}]>(<<{{
    \\<{([{{}}[<[[[<>{}]]]>[]]
;

test "Example" {
    const input = try common.readInput(test_allocator, EXAMPLE);
    defer {
        for (input) |i| test_allocator.free(i);
        test_allocator.free(input);
    }

    try expect((try calculateSyntaxError(test_allocator, input)) == 26397);
}

test "Check corrupt chunks" {
    try expect((try checkChunkCorruption(test_allocator, "()")) == 0);
    try expect((try checkChunkCorruption(test_allocator, "[]")) == 0);
    try expect((try checkChunkCorruption(test_allocator, "([])")) == 0);
    try expect((try checkChunkCorruption(test_allocator, "{()()()}")) == 0);
    try expect((try checkChunkCorruption(test_allocator, "<([{}])>")) == 0);
    try expect((try checkChunkCorruption(test_allocator, "[<>({}){}[([])<>]]")) == 0);
    try expect((try checkChunkCorruption(test_allocator, "(((((((((())))))))))")) == 0);

    try expect((try checkChunkCorruption(test_allocator, "(]")) == SCORE_RIGHT_BRACKET);
    try expect((try checkChunkCorruption(test_allocator, "{()()()>")) == SCORE_GT);
    try expect((try checkChunkCorruption(test_allocator, "(((()))}")) == SCORE_RIGHT_BRACE);
    try expect((try checkChunkCorruption(test_allocator, "<([]){()}[{}])")) == SCORE_RIGHT_PAREN);
}
