const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const print = std.debug.print;

const BingoCard = struct {
    values: [5][5]i8 = [_][5]i8{[_]i8{0} ** 5} ** 5,
    marked: [5][5]bool = [_][5]bool{[_]bool{false} ** 5} ** 5,

    winningNumber: i8 = 0,

    pub fn markAndCheck(self: *BingoCard, num: i8) bool {
        var rowTotals: [5]i8 = [_]i8{0} ** 5;
        var colTotals: [5]i8 = [_]i8{0} ** 5;

        for (self.values) |row, rowIdx| {
            for (row) |v, colIdx| {
                if (v == num) {
                    self.marked[rowIdx][colIdx] = true;
                }
                if (self.marked[rowIdx][colIdx]) {
                    rowTotals[rowIdx] += 1;
                    colTotals[colIdx] += 1;
                }
            }
        }
        for (rowTotals) |total| {
            if (total == 5) {
                self.winningNumber = num;
                return true;
            }
        }
        for (colTotals) |total| {
            if (total == 5) {
                self.winningNumber = num;
                return true;
            }
        }
        return false;
    }

    pub fn unmarkedTotal(self: *const BingoCard) i32 {
        var sum: i32 = 0;
        for (self.marked) |row, rowIdx| {
            for (row) |v, colIdx| {
                if (!v) {
                    sum += self.values[rowIdx][colIdx];
                }
            }
        }
        return sum;
    }

    pub fn answer(self: *const BingoCard) i32 {
        return self.winningNumber * self.unmarkedTotal();
    }
};

const BingoGame = struct {
    numbers: []i8,
    cards: []BingoCard,

    allocator: Allocator,

    const Self = @This();

    /// Deinitialize with `deinit` or use `toOwnedSlice`.
    pub fn init(allocator: Allocator, numbers: []i8, cards: []BingoCard) Self {
        return Self{
            .allocator = allocator,
            .numbers = numbers,
            .cards = cards,
        };
    }

    /// Release all allocated memory.
    pub fn deinit(self: Self) void {
        self.allocator.free(self.numbers);
        self.allocator.free(self.cards);
    }

    pub fn playGame(self: *BingoGame) anyerror!*const BingoCard {
        // Note if allowing replay (e.g. with different numbers), should reset card marking and winning number

        for (self.numbers) |n| {
            for (self.cards) |*c| {
                if (c.markAndCheck(n)) {
                    return c;
                }
            }
        }
        return error.NoResult;
    }

    pub fn playSquidGame(self: *BingoGame) anyerror!*const BingoCard {
        var squidCard: *const BingoCard = undefined;
        for (self.numbers) |n| {
            for (self.cards) |*c| {
                if (c.winningNumber == 0) {
                    if (c.markAndCheck(n)) {
                        squidCard = c;
                    }
                }
            }
        }
        return squidCard;
    }
};

fn readBingoGame(allocator: Allocator, lines: []const []const u8) anyerror!BingoGame {
    var numbers = ArrayList(i8).init(allocator);

    var iter = std.mem.split(u8, lines[0], ",");
    while (iter.next()) |num| {
        try numbers.append(try std.fmt.parseInt(i8, num, 10));
    }

    var cards = ArrayList(BingoCard).init(allocator);

    var line: usize = 1;

    while (line < lines.len) : (line += 6) {
        if (lines[line].len > 0) return error.InvalidData;

        var card = BingoCard{};

        var row: usize = 0;
        while (row < 5) : (row += 1) {
            var it = std.mem.tokenize(u8, lines[line + row + 1], " ");
            var col: usize = 0;
            while (it.next()) |num| {
                if (col >= 5) return error.InvalidData;
                card.values[row][col] = try std.fmt.parseInt(i8, num, 10);
                col += 1;
            }
        }
        try cards.append(card);
    }
    return BingoGame.init(allocator, numbers.toOwnedSlice(), cards.toOwnedSlice());
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = try common.readFile(allocator, "data/day4input.txt");

    var game = try readBingoGame(test_allocator, list);
    defer game.deinit();

    var result = try game.playGame();
    print("Day 4: winningNumber = {d}, unmarked = {d}, answer = {d}\n", .{ result.winningNumber, result.unmarkedTotal(), result.answer() });

    var squid = try game.playSquidGame();
    print("Day 4 Squid: winningNumber = {d}, unmarked = {d}, answer = {d}\n", .{ squid.winningNumber, squid.unmarkedTotal(), squid.answer() });
}

test "Example" {
    const input = try common.readInput(test_allocator,
        \\7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
        \\
        \\22 13 17 11  0
        \\ 8  2 23  4 24
        \\21  9 14 16  7
        \\ 6 10  3 18  5
        \\ 1 12 20 15 19
        \\
        \\ 3 15  0  2 22
        \\ 9 18 13 17  5
        \\19  8  7 25 23
        \\20 11 10 24  4
        \\14 21 16 12  6
        \\
        \\14 21 17 24  4
        \\10 16 15  9 19
        \\18  8 23 26 20
        \\22 11 13  6  5
        \\ 2  0 12  3  7
    );
    defer {
        for (input) |i| test_allocator.free(i);
        test_allocator.free(input);
    }

    var game = try readBingoGame(test_allocator, input);
    defer game.deinit();

    try expect(game.numbers[0] == 7);
    try expect(game.cards[0].values[0][0] == 22);
    try expect(game.cards[2].values[4][4] == 7);

    var result = try game.playGame();

    try expect(result.winningNumber == 24);
    try expect(result.unmarkedTotal() == 188);
    try expect(result.answer() == 4512);

    var squid = try game.playSquidGame();

    try expect(squid.winningNumber == 13);
    try expect(squid.unmarkedTotal() == 148);
    try expect(squid.answer() == 1924);
}
