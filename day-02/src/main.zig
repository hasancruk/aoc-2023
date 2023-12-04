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

// TODO struct to hold game data max seen. Or all seen then we can max it with a mem.max(slice)
// TODO struct to hold game config

const Summary = struct {
    red: u8 = 0,
    green: u8 = 0,
    blue: u8 = 0,

    pub fn init() Summary {
        return Summary{};
    }
};

const gameConfig = Summary{
    .red = 12,
    .green = 13,
    .blue = 14,
};

const Game = struct {
    id: u8,
    red: []u8,
    green: []u8,
    blue: []u8,

    // TODO will this need access to the allocator?
    pub fn init(id: u8, red: []u8, green: []u8, blue: []u8) Game {
        return Game{
            .id = id,
            .red = red,
            .green = green,
            .blue = blue,
        };
    }

    pub fn maxValues() ?Summary {
        return null;
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

// 3 blue, 4 red => [3, blue], [4, red]
fn extractSummary(summary: []const u8, allocator: Allocator) !Summary {
    var summaryData = try parseString(summary, ',', allocator);
    defer allocator.free(summaryData);

    var summaryStruct = Summary.init();

    for (summaryData) |cube| {
        var cubeTrimmed = std.mem.trim(u8, cube, " ");
        var cubeData = std.mem.splitScalar(u8, cubeTrimmed, ' ');
        var cubeCountStr = cubeData.next().?;
        var cubeColor = cubeData.next().?;

        var cubeCount = try std.fmt.parseUnsigned(u8, cubeCountStr, 10);

        if (std.mem.startsWith(u8, cubeColor, "red")) {
            summaryStruct.red = cubeCount;
        }

        if (std.mem.startsWith(u8, cubeColor, "green")) {
            summaryStruct.green = cubeCount;
        }

        if (std.mem.startsWith(u8, cubeColor, "blue")) {
            summaryStruct.blue = cubeCount;
        }
    }

    return summaryStruct;
}

// 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
fn extractSummaries(summaries: []const u8, allocator: Allocator) ![][]const u8 {
    var summariesData = try parseString(summaries, ';', allocator);
    defer allocator.free(summariesData);

    return summariesData;
}

// Game 1
fn extractGameId(gameId: []const u8, allocator: Allocator) ![]const u8 {
    var gameData = try parseString(gameId, ' ', allocator);
    defer allocator.free(gameData);

    var copy = try allocator.dupe(u8, gameData[1]);
    return copy;
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

// TODO Add toString
const Person = struct {
    const Self = @This();

    name: []const u8,
    age: u8,
    hobbies: []const []const u8,
    favoriteNumbers: []u8,
    allocator: Allocator,

    pub fn init(name: []const u8, age: u8, hobbies: []const []const u8, favoriteNumbers: []u8, allocator: Allocator) Person {
        return Person{
            .name = name,
            .age = age,
            .hobbies = hobbies,
            .favoriteNumbers = favoriteNumbers,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        test_allocator.free(self.hobbies);
        test_allocator.free(self.favoriteNumbers);
    }
};

test "Person" {
    var hobbiesList = ArrayList([]const u8).init(test_allocator);
    var numberList = ArrayList(u8).init(test_allocator);
    // defer hobbiesList.deinit();
    try hobbiesList.append("coding");
    try hobbiesList.append("cooking");
    try hobbiesList.append("games");

    try numberList.append(2);
    try numberList.append(9);
    try numberList.append(1);
    try numberList.append(18);
    // var hobbies = [_][]const u8{ "coding", "cooking", "games" };
    var hasan = Person.init("Hasan", 27, try hobbiesList.toOwnedSlice(), try numberList.toOwnedSlice(), test_allocator);
    defer hasan.deinit();

    std.debug.print("Person(name: {s}, age: {d}, hobby 2: {s}, number: {d})\n", .{ hasan.name, hasan.age, hasan.hobbies[1], hasan.favoriteNumbers[3] });
}

// test "extractSummary '3 red, 4 blue' to {red: 3, green: 0, blue: 4}" {
//     var result = try extractSummary("3 red, 4 blue", test_allocator);
//     defer test_allocator.free(result);
//     std.debug.print("(red: {d}, green: {d}, blue: {d})\n", .{ result.red, result.green, result.blue });
// }

test "extractGameId 'Game 102' to '102'" {
    var result = try extractGameId("Game 102", test_allocator);
    defer test_allocator.free(result);
    std.debug.print("{}\n", .{@TypeOf(result)});
    try std.testing.expect(0 == 0);
}

// test "splitScalar" {
//     var line = "Game 1: 3 blue, 4 red;";
//     var data = std.mem.splitScalar(u8, line, ':');

//     var text = data.next() orelse "nothing here";
//     var game = std.mem.splitScalar(u8, data.next().?, ',');
//     print(text);
//     print(game.next().?);

//     std.debug.print("{?s}\n", .{data.next()});
//     std.debug.print("{?s}\n", .{data.next()});

//     try std.testing.expect(0 == 0);
// }
