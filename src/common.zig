const std = @import("std");
const io = std.io;

pub fn readFile(allocator: std.mem.Allocator, filename: []const u8) anyerror![][]const u8 {
    var list = std.ArrayList([]const u8).init(allocator);

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var buf_reader = io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        try list.append(line);
    }

    return list.toOwnedSlice();
}

