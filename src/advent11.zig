const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const print = std.debug.print;

// HELPERS

fn parseArray(allocator: Allocator, input: []const u8) anyerror![]u8 {
    var result = ArrayList(u8).init(allocator);
    result.deinit();

    var it = std.mem.split(u8, input, "\n");
    while (it.next()) |l| {
        for (l) |v| {
            // use integers instead of digit characters
            try result.append(v - '0');
        }
    }
    return result.toOwnedSlice();
}

fn parseArrayLines(allocator: Allocator, input: [][]const u8) anyerror![]u8 {
    var result = ArrayList(u8).init(allocator);
    result.deinit();

    for (input) |l| {
        for (l) |v| {
            // use integers instead of digit characters
            try result.append(v - '0');
        }
    }
    return result.toOwnedSlice();
}

fn bloomInc(data: []u8, width: usize, i: usize, j: usize) i32 {
    var idx: usize = i * width + j;
    if (data[idx] != 0) data[idx] += 1;
    if (data[idx] > 9) {
        return bloom(data, width, i, j);
    }
    return 0;
}

fn bloom(data: []u8, width: usize, i: usize, j: usize) i32 {
    var total: i32 = 1;

    var idx: usize = i * width + j;
    data[idx] = 0;
    if (i > 0) {
        if (j > 0) total += bloomInc(data, width, i - 1, j - 1);
        total += bloomInc(data, width, i - 1, j);
        if (j < width - 1) total += bloomInc(data, width, i - 1, j + 1);
    }

    if (j > 0) total += bloomInc(data, width, i, j - 1);
    if (j < width - 1) total += bloomInc(data, width, i, j + 1);

    if (i < width - 1) {
        if (j > 0) total += bloomInc(data, width, i + 1, j - 1);
        total += bloomInc(data, width, i + 1, j);
        if (j < width - 1) total += bloomInc(data, width, i + 1, j + 1);
    }
    return total;
}

fn processStep(data: []u8, width: usize) i32 {
    var total: i32 = 0;

    var i: usize = 0;
    while (i < width) : (i += 1) {
        var j: usize = 0;
        while (j < width) : (j += 1) {
            data[i * width + j] += 1;
        }
    }

    i = 0;
    while (i < width) : (i += 1) {
        var j: usize = 0;
        while (j < width) : (j += 1) {
            if (data[i * width + j] > 9) {
                total += bloom(data, width, i, j);
            }
        }
    }
    return total;
}

fn processSteps(data: []u8, width: usize, steps: i32) i32 {
    var i: i32 = 0;
    var total: i32 = 0;
    while (i < steps) : (i += 1) {
        total += processStep(data, width);
    }
    return total;
}

fn findSimultaneousFlash(data: []u8, width: usize) !i32 {
    var step: i32 = 1;
    while (step < 10000) : (step += 1) {
        _ = processStep(data, width);
        if (std.mem.allEqual(u8, data, 0)) {
            return step;
        }
    }
    return error.NotFound;
}

// MAIN

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var input = try common.readFile(allocator, "data/day11input.txt");
    print("Day 11: total flashes = {d}\n", .{processSteps(try parseArrayLines(allocator, input), 10, 100)});
    print("Day 11: sync = {!d}\n", .{findSimultaneousFlash(try parseArrayLines(allocator, input), 10)});
}

// TESTING

const EXAMPLE =
    \\5483143223
    \\2745854711
    \\5264556173
    \\6141336146
    \\6357385478
    \\4167524645
    \\2176841721
    \\6882881134
    \\4846848554
    \\5283751526
;

test "Example Step 1" {
    const test_allocator = std.testing.test_allocator;
    const input = try parseArray(test_allocator, EXAMPLE);

    const step1 = try parseArray(test_allocator,
        \\6594254334
        \\3856965822
        \\6375667284
        \\7252447257
        \\7468496589
        \\5278635756
        \\3287952832
        \\7993992245
        \\5957959665
        \\6394862637
    );

    defer {
        test_allocator.free(input);
        test_allocator.free(step1);
    }

    _ = processStep(input, 10);
    try expect(std.mem.eql(u8, input, step1) == true);
}

test "Example Step 10" {
    const test_allocator = std.testing.test_allocator;
    const input = try parseArray(test_allocator, EXAMPLE);

    const step10 = try parseArray(test_allocator,
        \\0481112976
        \\0031112009
        \\0041112504
        \\0081111406
        \\0099111306
        \\0093511233
        \\0442361130
        \\5532252350
        \\0532250600
        \\0032240000
    );

    defer {
        test_allocator.free(input);
        test_allocator.free(step10);
    }

    var total: i32 = processSteps(input, 10, 10);
    try expect(std.mem.eql(u8, input, step10) == true);
    try expect(total == 204);
}

test "Example Step 100" {
    const test_allocator = std.testing.test_allocator;
    const input = try parseArray(test_allocator, EXAMPLE);

    const step100 = try parseArray(test_allocator,
        \\0397666866
        \\0749766918
        \\0053976933
        \\0004297822
        \\0004229892
        \\0053222877
        \\0532222966
        \\9322228966
        \\7922286866
        \\6789998766
    );

    defer {
        test_allocator.free(input);
        test_allocator.free(step100);
    }

    var total: i32 = processSteps(input, 10, 100);
    try expect(std.mem.eql(u8, input, step100) == true);
    try expect(total == 1656);
}

test "Example Simultaneous Flash" {
    const test_allocator = std.testing.test_allocator;
    const input = try parseArray(test_allocator, EXAMPLE);
    defer test_allocator.free(input);

    var step: i32 = try findSimultaneousFlash(input, 10);
    try expect(step == 195);
}

fn printMatrix(input: []u8, width: usize) void {
    for (input, 0..) |v, i| {
        print("{d: >3}", .{v});
        if (i % width == width - 1) print("\n", .{});
    }
    print("\n", .{});
}

test "Small time flash" {
    const test_allocator = std.testing.test_allocator;
    const input = try parseArray(test_allocator,
        \\11111
        \\19991
        \\19191
        \\19991
        \\11111
    );

    const step1 = try parseArray(test_allocator,
        \\34543
        \\40004
        \\50005
        \\40004
        \\34543
    );

    const step2 = try parseArray(test_allocator,
        \\45654
        \\51115
        \\61116
        \\51115
        \\45654
    );

    defer {
        test_allocator.free(input);
        test_allocator.free(step1);
        test_allocator.free(step2);
    }

    _ = processStep(input, 5);
    try expect(std.mem.eql(u8, input, step1) == true);

    _ = processStep(input, 5);
    try expect(std.mem.eql(u8, input, step2) == true);
}
