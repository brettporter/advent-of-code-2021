const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

// HELPERS

const ResultType = enum { corrupted, completed, ok };
const Result = union(ResultType) {
    corrupted: u64,
    completed: u64,
    ok: void,
};

const SCORE_RIGHT_PAREN = 3;
const SCORE_RIGHT_BRACKET = 57;
const SCORE_RIGHT_BRACE = 1197;
const SCORE_GT = 25137;

fn checkChunkCorruption(allocator: Allocator, input: []const u8) !Result {
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
                if (n.data != '(') return Result{ .corrupted = SCORE_RIGHT_PAREN };
            },
            ']' => {
                var n = pairs.popFirst().?;
                defer allocator.destroy(n);
                if (n.data != '[') return Result{ .corrupted = SCORE_RIGHT_BRACKET };
            },
            '}' => {
                var n = pairs.popFirst().?;
                defer allocator.destroy(n);
                if (n.data != '{') return Result{ .corrupted = SCORE_RIGHT_BRACE };
            },
            '>' => {
                var n = pairs.popFirst().?;
                defer allocator.destroy(n);
                if (n.data != '<') return Result{ .corrupted = SCORE_GT };
            },
            else => return error.InvalidData,
        }
    }

    if (pairs.len() == 0) return Result{ .ok = undefined };

    var completion = try ArrayList(u8).initCapacity(allocator, pairs.len());
    defer completion.deinit();
    while (pairs.popFirst()) |node| {
        try completion.append(switch (node.data) {
            '(' => ')',
            '[' => ']',
            '{' => '}',
            '<' => '>',
            else => unreachable(),
        });
        allocator.destroy(node);
    }

    return Result{ .completed = scoreCompletion(completion.items) };
}

fn scoreCompletion(input: []const u8) u64 {
    var total: u64 = 0;
    for (input) |c| {
        var score: u64 = switch (c) {
            ')' => 1,
            ']' => 2,
            '}' => 3,
            '>' => 4,
            else => unreachable(),
        };
        total = total * 5 + score;
    }
    return total;
}

fn findWinner(scores: []u64) u64 {
    std.sort.sort(u64, scores, {}, comptime std.sort.desc(u64));
    return scores[(scores.len - 1) / 2];
}

fn calculateSyntaxError(allocator: Allocator, input: [][]const u8) !u64 {
    var total: u64 = 0;
    for (input) |l| {
        var result = try checkChunkCorruption(allocator, l);
        if (result == ResultType.corrupted) total += result.corrupted;
        // ignore others
    }
    return total;
}

fn calculateCompletionScore(allocator: Allocator, input: [][]const u8) !u64 {
    var scores = ArrayList(u64).init(allocator);
    defer scores.deinit();
    for (input) |l| {
        var result = try checkChunkCorruption(allocator, l);
        if (result == ResultType.completed) try scores.append(result.completed);
        // ignore others
    }
    return findWinner(scores.items);
}

// MAIN

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var input = try common.readFile(allocator, "data/day10input.txt");
    print("Day 10: syntax error = {d}\n", .{calculateSyntaxError(allocator, input)});
    print("Day 10: completion score = {d}\n", .{calculateCompletionScore(allocator, input)});
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
    try expect((try calculateCompletionScore(test_allocator, input)) == 288957);
}

test "Check corrupt chunks" {
    try expect((try checkChunkCorruption(test_allocator, "()")) == ResultType.ok);
    try expect((try checkChunkCorruption(test_allocator, "[]")) == ResultType.ok);
    try expect((try checkChunkCorruption(test_allocator, "([])")) == ResultType.ok);
    try expect((try checkChunkCorruption(test_allocator, "{()()()}")) == ResultType.ok);
    try expect((try checkChunkCorruption(test_allocator, "<([{}])>")) == ResultType.ok);
    try expect((try checkChunkCorruption(test_allocator, "[<>({}){}[([])<>]]")) == ResultType.ok);
    try expect((try checkChunkCorruption(test_allocator, "(((((((((())))))))))")) == ResultType.ok);

    try expect((try checkChunkCorruption(test_allocator, "(]")).corrupted == SCORE_RIGHT_BRACKET);
    try expect((try checkChunkCorruption(test_allocator, "{()()()>")).corrupted == SCORE_GT);
    try expect((try checkChunkCorruption(test_allocator, "(((()))}")).corrupted == SCORE_RIGHT_BRACE);
    try expect((try checkChunkCorruption(test_allocator, "<([]){()}[{}])")).corrupted == SCORE_RIGHT_PAREN);
}

test "Check completion scoring" {
    try expect(scoreCompletion("}}]])})]") == 288957);
    try expect(scoreCompletion(")}>]})") == 5566);
    try expect(scoreCompletion("}}>}>))))") == 1480781);
    try expect(scoreCompletion("]]}}]}]}>") == 995444);
    try expect(scoreCompletion("])}>") == 294);
}

test "Check winner" {
    var scores = [_]u64{ 288957, 5566, 1480781, 995444, 294 };
    try expect(findWinner(scores[0..]) == 288957);
}
