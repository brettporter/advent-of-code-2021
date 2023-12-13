const std = @import("std");
const ArrayList = std.ArrayList;

const common = @import("common.zig");

const expect = std.testing.expect;
const print = std.debug.print;

const Command = enum { forward, up, down };
const Movement = union(Command) { forward: i32, up: i32, down: i32 };
const Position = struct {
    position: i32 = 0,
    depth: i32 = 0,
    aim: i32 = 0,

    fn answer(self: *Position) i32 {
        return self.position * self.depth;
    }

    fn followDirection1(self: *Position, direction: Movement) void {
        switch (direction) {
            .forward => |forward| self.position += forward,
            .up => |up| self.depth -= up,
            .down => |down| self.depth += down,
        }
    }

    fn followDirection2(self: *Position, direction: Movement) void {
        switch (direction) {
            .forward => |forward| {
                self.position += forward;
                self.depth += forward * self.aim;
            },
            .up => |up| self.aim -= up,
            .down => |down| self.aim += down,
        }
    }
};

fn parseDirection(str: []const u8) anyerror!Movement {
    var iter = std.mem.split(u8, str, " ");
    var cmd = iter.next().?;
    var amount = try std.fmt.parseInt(i32, iter.next().?, 10);
    if (std.mem.eql(u8, cmd, "forward")) {
        return Movement{ .forward = amount };
    } else if (std.mem.eql(u8, cmd, "up")) {
        return Movement{ .up = amount };
    } else if (std.mem.eql(u8, cmd, "down")) {
        return Movement{ .down = amount };
    } else {
        return error.InvalidCommand;
    }
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = try common.readFile(allocator, "data/day2input.txt");

    var result = Position{};
    for (list) |item| {
        result.followDirection1(try parseDirection(item));
    }

    print("Day 2 part 1: position = {d}, depth = {d}, answer = {d}\n", .{ result.position, result.depth, result.answer() });

    result = Position{};
    for (list) |item| {
        result.followDirection2(try parseDirection(item));
    }

    print("Day 2 part 2: position = {d}, depth = {d}, answer = {d}\n", .{ result.position, result.depth, result.answer() });
}

test "Parse directions" {
    var v = try parseDirection("forward 5");
    try expect(v.forward == 5);

    v = try parseDirection("up 3");
    try expect(v.up == 3);

    v = try parseDirection("down 8");
    try expect(v.down == 8);

    try std.testing.expectError(error.InvalidCommand, parseDirection("moove 1"));
    try std.testing.expectError(error.InvalidCharacter, parseDirection("down periscope"));
}

test "Example directions Part 1" {
    const directions = [_]Movement{ .{ .forward = 5 }, .{ .down = 5 }, .{ .forward = 8 }, .{ .up = 3 }, .{ .down = 8 }, .{ .forward = 2 } };

    var result = Position{};
    for (directions) |d| {
        result.followDirection1(d);
    }
    try expect(result.position == 15);
    try expect(result.depth == 10);
    try expect(result.answer() == 150);
}

test "Example directions Part 2" {
    const directions = [_]Movement{ .{ .forward = 5 }, .{ .down = 5 }, .{ .forward = 8 }, .{ .up = 3 }, .{ .down = 8 }, .{ .forward = 2 } };

    var result = Position{};
    for (directions) |d| {
        result.followDirection2(d);
    }
    try expect(result.position == 15);
    try expect(result.depth == 60);
    try expect(result.answer() == 900);
}
