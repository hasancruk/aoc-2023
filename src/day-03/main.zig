const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const test_allocator = std.testing.allocator;

const utils = @import("utilities");
const parseString = utils.parseString;
const sumList = utils.sumList;
const isDigit = utils.isDigit;
const charToDigit = utils.charToDigit;
const hash = utils.hash;
const concatDigits = utils.concatDigits;

const Coord = struct {
    column: u8,
    row: u8,
};

const NullableCoord = struct {
    column: ?u8,
    row: ?u8,
};

const Point = struct {
    column: u8,
    row: u8,
    value: u8,
};

const Symbol = Point;

const Number = struct {
    value: u32,
    points: []Point,
};

// TODO if one point gives you a number, then all the other points corresponding to the number much be added to the seen map
const Schematic = struct {
    // TODO make nullable
    height: u8,
    width: u8,

    allNumbers: AutoHashMap([16]u8, Number),
    seenNumbers: AutoHashMap([16]u8, Point),
    points: ArrayList([]Point),
    symbols: ArrayList(Symbol),
    allocator: Allocator,

    pub fn init(allocator: Allocator) Schematic {
        return .{
            .allNumbers = AutoHashMap([16]u8, Number).init(allocator),
            .seenNumbers = AutoHashMap([16]u8, Point).init(allocator),
            .points = ArrayList([]Point).init(allocator),
            .symbols = ArrayList(Symbol).init(allocator),
            .allocator = allocator,
            .width = @as(u8, 0),
            .height = @as(u8, 0),
        };
    }

    pub fn setDimension(self: *Schematic, width: u8, height: u8) void {
        self.width = width;
        self.height = height;
    }

    pub fn insertSymbolsRow(self: *Schematic, symbols: []Symbol) !void {
        try self.symbols.appendSlice(symbols);
    }

    pub fn insertPointsRow(self: *Schematic, points: [][]Point) !void {
        // TODO Do I need points? If I remove it, I might need to do the clean up here
        try self.points.appendSlice(points);

        for (points) |pointGroup| {
            var number = try convertPointsToNumber(pointGroup);

            for (pointGroup) |point| {
                var coord: Coord = .{
                    .column = point.column,
                    .row = point.row,
                };
                var hashedCoord = hash(coord);
                try self.allNumbers.put(hashedCoord, number);
            }
        }
    }

    pub fn findAdjacent(self: *Schematic) ![]Number {
        var numberMatches = ArrayList(Number).init(self.allocator);
        defer numberMatches.deinit();

        for (self.symbols.items) |symbol| {
            var searchCoords = try getSearchCoords(symbol, self.width, self.height, self.allocator);
            defer self.allocator.free(searchCoords);

            searchBlock: for (searchCoords) |coord| {
                var hashedCoord = hash(coord);
                var match = self.allNumbers.get(hashedCoord);

                var isSeen = false;

                if (match) |matched| {
                    for (matched.points) |point| {
                        var hashedPoint = hash(point);
                        var seenPoint = self.seenNumbers.get(hashedPoint);
                        if (seenPoint != null) {
                            // TODO this might not be necessary
                            isSeen = true;
                            continue :searchBlock;
                        } else {
                            try self.seenNumbers.put(hashedPoint, point);
                        }
                    }

                    if (!isSeen) {
                        try numberMatches.append(matched);
                    }
                }
            }
        }

        return try numberMatches.toOwnedSlice();
    }

    pub fn deinit(self: *Schematic) void {
        for (self.points.items) |point| {
            self.allocator.free(point);
        }
        self.points.deinit();
        self.symbols.deinit();
        self.allNumbers.deinit();
        self.seenNumbers.deinit();
    }
};

fn getSearchCoords(symbol: Symbol, width: u8, height: u8, allocator: Allocator) ![]Coord {
    var list = ArrayList(Coord).init(allocator);
    defer list.deinit();
    // top right bottom left
    var top = .{
        .column = symbol.column,
        .row = std.math.add(u8, symbol.row, 1) catch null,
    };
    var topRight = .{
        .column = std.math.add(u8, symbol.column, 1) catch null,
        .row = std.math.add(u8, symbol.row, 1) catch null,
    };
    var right = .{
        .column = std.math.add(u8, symbol.column, 1) catch null,
        .row = symbol.row,
    };
    var bottomRight = .{
        .column = std.math.add(u8, symbol.column, 1) catch null,
        .row = std.math.sub(u8, symbol.row, 1) catch null,
    };
    var bottom = .{
        .column = symbol.column,
        .row = std.math.sub(u8, symbol.row, 1) catch null,
    };
    var bottomLeft = .{
        .column = std.math.sub(u8, symbol.column, 1) catch null,
        .row = std.math.sub(u8, symbol.row, 1) catch null,
    };
    var left = .{
        .column = std.math.sub(u8, symbol.column, 1) catch null,
        .row = symbol.row,
    };
    var topLeft = .{
        .column = std.math.sub(u8, symbol.column, 1) catch null,
        .row = std.math.add(u8, symbol.row, 1) catch null,
    };
    var allCoords = [_]NullableCoord{ top, topRight, right, bottomRight, bottom, bottomLeft, left, topLeft };

    for (allCoords) |coord| {
        var x = coord.column;
        var y = coord.row;

        if (x == null or y == null or x.? > width or y.? > height) {
            continue;
        }
        try list.append(.{
            .column = coord.column.?,
            .row = coord.row.?,
        });
    }

    return try list.toOwnedSlice();
}

fn convertPointsToNumber(points: []Point) !Number {
    var buffer: [512]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    var nums = ArrayList(u8).init(allocator);

    for (points) |point| {
        try nums.append(point.value);
    }

    var number = concatDigits(try nums.toOwnedSlice());
    return Number{
        .value = number,
        .points = points,
    };
}

// TODO Construct clear error types to return if this goes wrong
// TODO u8 might be too small
// "..*617....885...*....-....=...*..."
fn extractLineIntoSchematic(row: u8, text: []const u8, schematic: *Schematic, allocator: Allocator) !void {
    var pointsList = ArrayList([]Point).init(allocator);
    defer pointsList.deinit();
    var symbolsList = ArrayList(Symbol).init(allocator);
    defer symbolsList.deinit();

    var pointBuffer = ArrayList(Point).init(allocator);
    defer pointBuffer.deinit();

    var numberStarted = false;
    for (text, 0..) |character, col| {
        var column = @as(u8, @intCast(col));
        switch (character) {
            // TODO this list was eye balled and could potentially miss a symbol
            '.', '*', '-', '/', '%', '$', '@', '+', '=', '#', '&' => |c| {
                if (c != '.') {
                    // TODO handle symbol logic
                    var symbol = Symbol{
                        .column = column,
                        .row = row,
                        .value = c,
                    };
                    try symbolsList.append(symbol);
                }
                if (numberStarted) {
                    numberStarted = false;
                    try pointsList.append(try pointBuffer.toOwnedSlice());
                }
            },
            '0'...'9' => |c| {
                if (!numberStarted) {
                    numberStarted = true;
                }

                var point = Point{
                    .column = column,
                    .row = row,
                    .value = charToDigit(c),
                };
                try pointBuffer.append(point);
            },
            else => std.debug.print("No character", .{}),
        }
    }

    if (pointBuffer.items.len > 0) {
        try pointsList.append(try pointBuffer.toOwnedSlice());
    }

    try schematic.insertSymbolsRow(symbolsList.items);
    try schematic.insertPointsRow(pointsList.items);
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const inputFile = "src/day-03/input.txt";
    const file = try std.fs.cwd().openFile(inputFile, .{});
    defer file.close();

    var list = ArrayList(u8).init(allocator);
    defer list.deinit();

    var powers = ArrayList(u16).init(allocator);
    defer powers.deinit();

    var bufReader = std.io.bufferedReader(file.reader());
    var reader = bufReader.reader();
    var buffer: [512]u8 = undefined;
    // TODO might have to read the entire file into memory for this one
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        _ = line;
        // var game = try extractGameData(line, allocator);
        // defer game.deinit();

        // var power = game.power();
        // try powers.append(power);

        // if (isGamePossible(game, gameConfig)) {
        //     try list.append(game.id);
        // }
    }
    var total = sumList(u8, list);
    std.debug.print("Total: {d}\n", .{total});
}

test "findAdjacent numbers '..*617..123-.'" {
    var schematic = Schematic.init(test_allocator);
    defer schematic.deinit();

    try extractLineIntoSchematic(@as(u8, 0), "..*617*..123-.", &schematic, test_allocator);

    schematic.setDimension(@as(u8, 14), @as(u8, 1));

    var results = try schematic.findAdjacent();
    defer test_allocator.free(results);

    for (results) |num| {
        std.debug.print("{d}\n", .{num.value});
    }
    // std.debug.print("{any}\n", .{@TypeOf(&expected[0..1])});
    // try std.testing.expectEqualSlices([]Point, &expected, result);
}

// test "extractToPoints without symbols '..*617....885...*....-....=...*...'" {
//     var schematic = Schematic.init(test_allocator);
//     defer schematic.deinit();

//     try extractLineIntoSchematic(@as(u8, 0), "..*617....885...*....-....=...*...", &schematic, test_allocator);

//     for (schematic.points.items) |points| {
//         std.debug.print("Point set\n", .{});
//         for (points) |point| {
//             std.debug.print("[{d}, {d}]: {d}\n", .{ point.column, point.row, point.value });
//         }
//     }

//     for (schematic.symbols.items) |symbol| {
//         std.debug.print("Symbol set\n", .{});

//         std.debug.print("[{d}, {d}]: {c}\n", .{ symbol.column, symbol.row, symbol.value });
//     }

//     // std.debug.print("{any}\n", .{@TypeOf(&expected[0..1])});
//     // try std.testing.expectEqualSlices([]Point, &expected, result);
// }

test "convertPointsToNumber 3 points to 921" {
    var pointA = Point{
        .column = @as(u8, 2),
        .row = @as(u8, 2),
        .value = @as(u8, 9),
    };
    var pointB = Point{
        .column = @as(u8, 2),
        .row = @as(u8, 3),
        .value = @as(u8, 2),
    };
    var pointC = Point{
        .column = @as(u8, 2),
        .row = @as(u8, 4),
        .value = @as(u8, 1),
    };

    var points = [_]Point{ pointA, pointB, pointC };
    var number = try convertPointsToNumber(&points);

    try std.testing.expect(number.value == 921);
    try std.testing.expectEqualSlices(Point, &points, number.points);
}
