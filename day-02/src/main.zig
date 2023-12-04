const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const test_allocator = std.testing.allocator;

// TODO this can be pulled into a common utils folder
fn sumList(list: ArrayList(u8)) u16 {
    var sum: u16 = 0;

    for (list.items) |n| {
        sum += n;
    }

    return sum;
}

const Summary = struct {
    red: u8,
    green: u8,
    blue: u8,

    pub fn init(red: u8, green: u8, blue: u8) Summary {
        return Summary{
            .red = red,
            .green = green,
            .blue = blue,
        };
    }
};

const gameConfig = Summary{
    .red = 12,
    .green = 13,
    .blue = 14,
};

const Game = struct {
    const Self = @This();

    id: u8,
    red: []u8,
    green: []u8,
    blue: []u8,
    allocator: Allocator,

    pub fn init(id: u8, red: []u8, green: []u8, blue: []u8, allocator: Allocator) Game {
        return Game{
            .id = id,
            .red = red,
            .green = green,
            .blue = blue,
            .allocator = allocator,
        };
    }

    // TODO all seen then we can max it with a mem.max(slice)
    pub fn maxValues() ?Summary {
        return null;
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.red);
        self.allocator.free(self.green);
        self.allocator.free(self.blue);
    }
};

fn parseGameData(game: []const u8) Game {
    _ = game;
}

fn parseString(string: []const u8, delimiter: u8, allocator: Allocator) ![][]const u8 {
    var list = ArrayList([]const u8).init(allocator);
    var iter = std.mem.splitScalar(u8, string, delimiter);
    while (iter.next()) |str| {
        try list.append(str);
    }
    return list.toOwnedSlice();
}

fn extractGameId(gameLabel: []const u8, allocator: Allocator) !u8 {
    var gameData = try parseString(gameLabel, ' ', allocator);
    defer allocator.free(gameData);

    return try std.fmt.parseUnsigned(u8, gameData[1], 10);
}

fn extractSummary(summary: []const u8, allocator: Allocator) !Summary {
    var summaryData = try parseString(summary, ',', allocator);
    defer allocator.free(summaryData);

    var redCount: ?u8 = null;
    var greenCount: ?u8 = null;
    var blueCount: ?u8 = null;

    for (summaryData) |cube| {
        var cubeTrimmed = std.mem.trim(u8, cube, " ");
        var cubeData = std.mem.splitScalar(u8, cubeTrimmed, ' ');
        var cubeCountStr = cubeData.next().?;
        var cubeColor = cubeData.next().?;

        var cubeCount = try std.fmt.parseUnsigned(u8, cubeCountStr, 10);

        if (std.mem.startsWith(u8, cubeColor, "red")) {
            redCount = cubeCount;
        }

        if (std.mem.startsWith(u8, cubeColor, "green")) {
            greenCount = cubeCount;
        }

        if (std.mem.startsWith(u8, cubeColor, "blue")) {
            blueCount = cubeCount;
        }
    }

    return Summary.init(redCount orelse 0, greenCount orelse 0, blueCount orelse 0);
}

// 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
fn extractSummaries(summaries: []const u8, allocator: Allocator) ![][]const u8 {
    var summariesData = try parseString(summaries, ';', allocator);
    defer allocator.free(summariesData);

    return summariesData;
}

// Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
fn extractGameData(text: []const u8, allocator: Allocator) Game {
    _ = allocator;
    var data = std.mem.splitScalar(u8, text, ':');

    var gameRaw = data.next().?;
    _ = gameRaw;
    var summariesRaw = data.next().?;
    _ = summariesRaw;

    // var summaries = parseSummaries(summariesRaw, allocator);
    // defer allocator.free(summaries);
}

// fn gameData() void {}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const inputFile = "input.txt";
    const file = try std.fs.cwd().openFile(inputFile, .{});
    defer file.close();

    var list = ArrayList(u8).init(allocator);
    defer list.deinit();

    var bufReader = std.io.bufferedReader(file.reader());
    var reader = bufReader.reader();
    var buffer: [512]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        _ = line;
        // var num = 0;
        // try list.append(num);
    }
    var total = sumList(list);
    std.debug.print("{d}\n", .{total});
}

fn print(text: []const u8) void {
    std.debug.print("{s}\n", .{text});
}

test "extractSummary '13 red, 2 blue, 8 green' to {red: 13, green: 8, blue: 2}" {
    var result = try extractSummary("13 red, 2 blue, 8 green", test_allocator);

    try std.testing.expect(result.red == 13);
    try std.testing.expect(result.green == 8);
    try std.testing.expect(result.blue == 2);
}

test "extractSummary '3 red, 4 blue' to {red: 3, green: 0, blue: 4}" {
    var result = try extractSummary("3 red, 4 blue", test_allocator);

    try std.testing.expect(result.red == 3);
    try std.testing.expect(result.green == 0);
    try std.testing.expect(result.blue == 4);
}

test "extractGameId 'Game 102' to '102'" {
    var result = try extractGameId("Game 102", test_allocator);

    try std.testing.expect(result == 102);
}
