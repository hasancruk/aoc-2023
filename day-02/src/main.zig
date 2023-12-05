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

    pub fn maxValues(self: Self) Summary {
        var maxRed = std.mem.max(u8, self.red);
        var maxGreen = std.mem.max(u8, self.green);
        var maxBlue = std.mem.max(u8, self.blue);

        return Summary.init(maxRed, maxGreen, maxBlue);
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.red);
        self.allocator.free(self.green);
        self.allocator.free(self.blue);
    }
};

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

fn extractSummaries(summaries: []const u8, allocator: Allocator) ![3][]u8 {
    var summariesData = try parseString(summaries, ';', allocator);
    defer allocator.free(summariesData);

    var reds = ArrayList(u8).init(allocator);
    var greens = ArrayList(u8).init(allocator);
    var blues = ArrayList(u8).init(allocator);

    for (summariesData) |summary| {
        var summaryData = try extractSummary(summary, allocator);

        try reds.append(summaryData.red);
        try greens.append(summaryData.green);
        try blues.append(summaryData.blue);
    }

    return [_][]u8{ try reds.toOwnedSlice(), try greens.toOwnedSlice(), try blues.toOwnedSlice() };
}

fn extractGameData(text: []const u8, allocator: Allocator) !Game {
    var data = std.mem.splitScalar(u8, text, ':');

    var gameRaw = data.next().?;
    var gameId = try extractGameId(gameRaw, allocator);
    var summariesRaw = data.next().?;
    var summaries = try extractSummaries(summariesRaw, allocator);

    var game = Game.init(gameId, summaries[0], summaries[1], summaries[2], allocator);
    return game;
}

const gameConfig = Summary{
    .red = 12,
    .green = 13,
    .blue = 14,
};

fn isGamePossible(game: Game, config: Summary) bool {
    var maxes = game.maxValues();
    return (maxes.red <= config.red) and (maxes.green <= config.green) and (maxes.blue <= config.blue);
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

test "isGamePossible not possible 'Game 1: 23 blue, 4 red; 1 red, 2 green, 6 blue; 2 green'" {
    var result = try extractGameData("Game 1: 23 blue, 4 red; 1 red, 2 green, 6 blue; 2 green", test_allocator);
    defer result.deinit();

    var isPossible = isGamePossible(result, gameConfig);

    try std.testing.expect(!isPossible);
}

test "isGamePossible possible 'Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green'" {
    var result = try extractGameData("Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green", test_allocator);
    defer result.deinit();

    var isPossible = isGamePossible(result, gameConfig);

    try std.testing.expect(isPossible);
}

test "extractGameData maxValues 'Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green'" {
    var result = try extractGameData("Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green", test_allocator);
    defer result.deinit();

    var summary = result.maxValues();

    try std.testing.expect(summary.red == 4);
    try std.testing.expect(summary.green == 2);
    try std.testing.expect(summary.blue == 6);
}

test "extractGameData 'Game 20: 4 green, 3 blue, 1 red; 9 red, 14 blue, 9 green; 1 blue, 17 red, 2 green; 8 red, 13 blue, 8 green; 7 red, 2 green, 20 blue; 6 green, 13 red, 5 blue'" {
    var result = try extractGameData("Game 20: 4 green, 3 blue, 1 red; 9 red, 14 blue, 9 green; 1 blue, 17 red, 2 green; 8 red, 13 blue, 8 green; 7 red, 2 green, 20 blue; 6 green, 13 red, 5 blue", test_allocator);
    var expectedReds = [_]u8{ 1, 9, 17, 8, 7, 13 };
    var expectedGreens = [_]u8{ 4, 9, 2, 8, 2, 6 };
    var expectedBlues = [_]u8{ 3, 14, 1, 13, 20, 5 };
    defer result.deinit();

    try std.testing.expect(result.id == 20);
    try std.testing.expect(std.mem.eql(u8, result.red, &expectedReds));
    try std.testing.expect(std.mem.eql(u8, result.green, &expectedGreens));
    try std.testing.expect(std.mem.eql(u8, result.blue, &expectedBlues));
}

test "extractGameData 'Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green'" {
    var result = try extractGameData("Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green", test_allocator);
    var expectedReds = [_]u8{ 4, 1, 0 };
    var expectedGreens = [_]u8{ 0, 2, 2 };
    var expectedBlues = [_]u8{ 3, 6, 0 };
    defer result.deinit();

    try std.testing.expect(result.id == 1);
    try std.testing.expect(std.mem.eql(u8, result.red, &expectedReds));
    try std.testing.expect(std.mem.eql(u8, result.green, &expectedGreens));
    try std.testing.expect(std.mem.eql(u8, result.blue, &expectedBlues));
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
