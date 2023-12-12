const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const test_allocator = std.testing.allocator;

const utils = @import("utilities");
const sumList = utils.sumList;

const Scratchcard = struct {
    id: u8,
    winningSet: AutoHashMap(u8, void),
    numbers: ArrayList(u8),

    pub fn init(id: u8, allocator: Allocator) Scratchcard {
        return .{
            .id = id,
            .winningSet = AutoHashMap(u8, void).init(allocator),
            .numbers = ArrayList(u8).init(allocator),
        };
    }

    pub fn insertWinningNumber(self: *Scratchcard, number: u8) !void {
        try self.winningSet.put(number, {});
    }

    pub fn insertNumber(self: *Scratchcard, number: u8) !void {
        try self.numbers.append(number);
    }

    pub fn calculatePoints(self: *Scratchcard) ?u32 {
        var matchCount: u32 = 0;

        for (self.numbers.items) |number| {
            if (self.winningSet.get(number) != null) {
                matchCount += 1;
            }
        }

        return if (matchCount == 0) null else std.math.pow(u32, 2, matchCount - 1);
    }

    pub fn deinit(self: *Scratchcard) void {
        self.winningSet.deinit();
        self.numbers.deinit();
    }
};

fn extractToScratchcard(text: []const u8, allocator: Allocator) !Scratchcard {
    var data = std.mem.splitScalar(u8, text, ':');
    var label = data.next().?;
    var id = try extractId(label);

    var trimmedCardData = std.mem.trim(u8, data.next().?, " ");
    var cardData = std.mem.splitScalar(u8, trimmedCardData, '|');

    var trimmedWinning = std.mem.trim(u8, cardData.next().?, " ");
    var winningIter = std.mem.tokenizeScalar(u8, trimmedWinning, ' ');

    var trimmedNumbers = std.mem.trim(u8, cardData.next().?, " ");
    var numbersIter = std.mem.tokenizeScalar(u8, trimmedNumbers, ' ');

    var card = Scratchcard.init(id, allocator);

    while (winningIter.next()) |winningNumber| {
        try card.insertWinningNumber(try std.fmt.parseUnsigned(u8, winningNumber, 10));
    }

    while (numbersIter.next()) |number| {
        try card.insertNumber(try std.fmt.parseUnsigned(u8, number, 10));
    }

    return card;
}

fn extractId(label: []const u8) !u8 {
    var tokens = std.mem.tokenizeScalar(u8, label, ' ');
    _ = tokens.next();
    var id = tokens.next().?;

    return try std.fmt.parseUnsigned(u8, id, 10);
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const inputFile = "src/day-04/input.txt";
    const file = try std.fs.cwd().openFile(inputFile, .{});
    defer file.close();

    var list = ArrayList(u32).init(allocator);
    defer list.deinit();

    var bufReader = std.io.bufferedReader(file.reader());
    var reader = bufReader.reader();
    var buffer: [512]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var card = try extractToScratchcard(line, allocator);
        defer card.deinit();

        var maybeCount = card.calculatePoints();
        if (maybeCount) |count| {
            try list.append(count);
        }
    }

    var total = sumList(u32, list);
    std.debug.print("Total: {d}\n", .{total});
}

test "scratchcard" {
    var card = try extractToScratchcard("Card   1: 58 96 35 20 93 34 10 27 37 30 | 99 70 93 11 63 41 37 29  7 28 34 10 40 96 38 35 27 30 20 21  4 51 58 39 56", test_allocator);
    defer card.deinit();

    std.debug.print("Card ID: {d}, Point: {?d}\n", .{ card.id, card.calculatePoints() });
}
