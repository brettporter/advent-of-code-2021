const std = @import("std");
const io = std.io;

pub fn readInput(allocator: std.mem.Allocator, input: []const u8) anyerror![][]const u8 {
    return readLines(allocator, io.fixedBufferStream(input).reader());
}

pub fn readFile(allocator: std.mem.Allocator, filename: []const u8) anyerror![][]const u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    return readLines(allocator, file.reader());
}

fn readLines(allocator: std.mem.Allocator, reader: anytype) anyerror![][]const u8 {
    var buf_reader = io.bufferedReader(reader);
    var in_stream = buf_reader.reader();

    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();

    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        try list.append(line);
    }

    return list.toOwnedSlice();
}

// TESTING

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

test "Read File" {
    var list = try readFile(test_allocator, "data/day1input.txt");
    defer {
        for (list) |i| test_allocator.free(i);
        test_allocator.free(list);
    }

    try expect(list.len == 2000);
}

test "Read Input" {
    var list = try readInput(test_allocator,
        \\The quick brown fox
        \\jumps over the lazy
        \\dog
    );
    defer {
        for (list) |i| test_allocator.free(i);
        test_allocator.free(list);
    }

    try expect(list.len == 3);
}
