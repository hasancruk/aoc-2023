const std = @import("std");
const ArrayList = std.ArrayList;
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

const Schematic = struct {
    height: usize,
    width: usize,
    points: [][]Point,
    symbols: []Symbol,
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

// TODO u8 might be too small
// "..*617....885...*....-....=...*..."
fn extractToPoints(row: u8, text: []const u8, allocator: Allocator) ![][]Point {
    var list = ArrayList([]Point).init(allocator);
    defer list.deinit();

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
                }
                if (numberStarted) {
                    numberStarted = false;
                    try list.append(try pointBuffer.toOwnedSlice());
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
            // TODO add symbols logic
            else => std.debug.print("No character", .{}),
        }
    }

    if (pointBuffer.items.len > 0) {
        try list.append(try pointBuffer.toOwnedSlice());
    }

    return try list.toOwnedSlice();
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

// test "extractToPoints with symbols" {
//     const result = try extractToPoints(@as(u8, 0), "..*617....885...*....-....=...*...", test_allocator);
//     defer {
//         for (result) |r| {
//             test_allocator.free(r);
//         }
//         test_allocator.free(result);
//     }

//     for (result) |points| {
//         std.debug.print("Point set\n", .{});
//         for (points) |point| {
//             std.debug.print("[{d}, {d}]: {d}\n", .{ point.column, point.row, point.value });
//         }
//     }
// }

// test "extractToPoints without symbols '21...664...99..12'" {
//     const result = try extractToPoints(@as(u8, 0), "21...664...99..12", test_allocator);
//     defer {
//         for (result) |r| {
//             test_allocator.free(r);
//         }
//         test_allocator.free(result);
//     }

//     for (result) |points| {
//         std.debug.print("Point set\n", .{});
//         for (points) |point| {
//             std.debug.print("[{d}, {d}]: {d}\n", .{ point.column, point.row, point.value });
//         }
//     }
// }

test "extractToPoints without symbols '.....664...998...'" {
    const result = try extractToPoints(@as(u8, 0), ".....664...998...", test_allocator);
    defer {
        for (result) |r| {
            test_allocator.free(r);
        }
        test_allocator.free(result);
    }

    var expected = [2][3]Point{
        [_]Point{
            .{ .column = 5, .row = 0, .value = 6 },
            .{ .column = 6, .row = 0, .value = 6 },
            .{ .column = 7, .row = 0, .value = 4 },
        },
        [_]Point{
            .{ .column = 11, .row = 0, .value = 9 },
            .{ .column = 12, .row = 0, .value = 9 },
            .{ .column = 13, .row = 0, .value = 8 },
        },
    };
    _ = expected;

    // for (result) |points| {
    //     std.debug.print("Point set\n", .{});
    //     for (points) |point| {
    //         std.debug.print("[{d}, {d}]: {d}\n", .{ point.column, point.row, point.value });
    //     }
    // }

    // std.debug.print("{any}\n", .{@TypeOf(&expected[0..1])});
    // try std.testing.expectEqualSlices([]Point, &expected, result);
}

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
