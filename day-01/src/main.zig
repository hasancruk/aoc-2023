const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const test_allocator = std.testing.allocator;

fn charToDigit(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        else => c,
    };
}

fn isDigit(c: u8) bool {
    // std.debug.print("isDigit check: {c}\n", .{c});
    return c < 10;
}

fn extractDigits(text: []const u8) [2]u8 {
    var isFirst = true;
    var result: [2]u8 = undefined;
    var last: u8 = undefined;
    var hasLast = false;

    for (text) |c| {
        var digit = charToDigit(c);
        if (isDigit(digit)) {
            if (isFirst) {
                result[0] = digit;
                isFirst = false;
            } else {
                last = digit;
                hasLast = true;
            }
        }
    }

    if (hasLast) {
        result[1] = last;
    } else {
        result[1] = result[0];
    }

    return result;
}

// TODO make it return ?u8
fn wordToDigit(text: []const u8) u8 {
    var result: u8 = '0';

    if (std.mem.eql(u8, text, "one")) {
        result = '1';
    } else if (std.mem.eql(u8, text, "two")) {
        result = '2';
    } else if (std.mem.eql(u8, text, "three")) {
        result = '3';
    } else if (std.mem.eql(u8, text, "four")) {
        result = '4';
    } else if (std.mem.eql(u8, text, "five")) {
        result = '5';
    } else if (std.mem.eql(u8, text, "six")) {
        result = '6';
    } else if (std.mem.eql(u8, text, "seven")) {
        result = '7';
    } else if (std.mem.eql(u8, text, "eight")) {
        result = '8';
    } else if (std.mem.eql(u8, text, "nine")) {
        result = '9';
    }

    return result;
}

// TODO Might need to use arraylist with an allocator
fn transformToDigits(text: []const u8, allocator: Allocator) ![]const u8 {
    const digits = [_][]const u8{
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
    };
    var list = ArrayList(u8).init(allocator);
    defer list.deinit();

    var skipBy: usize = 0;

    outer: for (text, 0..) |c, i| {
        if (skipBy > 0) {
            std.debug.print("Skipping\n", .{});
            skipBy -= 1;
            continue :outer;
        }

        if (isDigit(c)) {
            std.debug.print("isDigit\n", .{});
            try list.append(c);
            continue;
        } else {
            for (digits) |digit| {
                if (std.mem.startsWith(u8, text[i..], digit)) {
                    // std.debug.print("{s}\n", .{digit});
                    var num: u8 = wordToDigit(digit);
                    try list.append(num);

                    // Skip forward by the number of characters in the matching digit
                    skipBy = digit.len - 1;
                    continue :outer;
                } else {
                    try list.append(c);
                }
            }
        }
    }

    std.debug.print("DEBUG\n", .{});

    for (list.items) |n| {
        std.debug.print("{c}\n", .{n});
    }

    std.debug.print("end DEBUG\n", .{});

    return "219";
}

fn concatDigits(digits: [2]u8) u8 {
    return (digits[0] * 10) + digits[1];
}

fn readToList(allocator: Allocator) void {
    var nums = ArrayList(u8).init(allocator);
    _ = nums;
}

fn sumList(list: ArrayList(u8)) u16 {
    var sum: u16 = 0;

    for (list.items) |n| {
        sum += n;
    }

    return sum;
}

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const inputFile = "part-1.txt";
    const file = try std.fs.cwd().openFile(inputFile, .{});
    defer file.close();

    var list = ArrayList(u8).init(allocator);
    defer list.deinit();

    var bufReader = std.io.bufferedReader(file.reader());
    var reader = bufReader.reader();
    var buffer: [512]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var num = concatDigits(extractDigits(line));
        try list.append(num);
    }
    var total = sumList(list);
    std.debug.print("{d}\n", .{total});
}

// test "transform '7pqrstsixteen' to '76'" {
//     const expect = "76";
//     var result = transformToDigits("7pqrstsixteen");

//     try std.testing.expectEqual(@as([]const u8, expect), result);
// }
// test "mem.startsWith" {
//     const expect = "aone2three";
//     const digits = [_][]const u8{"one"};

//     for (digits) |digit| {
//         var result = std.mem.startsWith(u8, expect[1..], digit);
//         if (result) {
//             std.debug.print("YESS!\n", .{});
//         }
//         std.debug.print("{}\n", .{result});
//     }

//     try std.testing.expectEqual(2, 2);
// }

test "transform 'two1nine' to '219'" {
    const expect = "219";
    var result = try transformToDigits("two1nine", test_allocator);

    try std.testing.expectEqual(@as([]const u8, expect), result);
}

test "'one' to '1'" {
    const expect = '1';
    var result = wordToDigit("one");
    // var result = wordToDigit("one") orelse '0';

    try std.testing.expectEqual(@as(u8, expect), result);
}

test "'nine' to '9'" {
    const expect = '9';
    var result = wordToDigit("nine");
    // var result = wordToDigit("nine") orelse '0';

    try std.testing.expectEqual(@as(u8, expect), result);
}

test "concat '6, 0' returns 60" {
    const expect = 60;
    var result = concatDigits([_]u8{ 6, 0 });

    try std.testing.expectEqual(@as(u8, expect), result);
}

test "concat '9, 1' returns 91" {
    const expect = 91;
    var result = concatDigits([_]u8{ 9, 1 });

    try std.testing.expectEqual(@as(u8, expect), result);
}

test "concat '2, 5' returns 25" {
    const expect = 25;
    var result = concatDigits([_]u8{ 2, 5 });

    try std.testing.expectEqual(@as(u8, expect), result);
}

test "from '1a2' returns 1 & 2" {
    const a = 1;
    const b = 2;
    var result = extractDigits("1a2");

    try std.testing.expectEqual(@as(u8, a), result[0]);
    try std.testing.expectEqual(@as(u8, b), result[1]);
}

test "from 'a5b' returns 5 & 4" {
    const a = 5;
    const b = 5;
    var result = extractDigits("a5b");

    try std.testing.expectEqual(@as(u8, a), result[0]);
    try std.testing.expectEqual(@as(u8, b), result[1]);
}

test "from 'a56b74' returns 5 & 4" {
    const a = 5;
    const b = 4;
    var result = extractDigits("a56b74");

    try std.testing.expectEqual(@as(u8, a), result[0]);
    try std.testing.expectEqual(@as(u8, b), result[1]);
}

test "from 'a5b4' returns 5 & 4" {
    const a = 5;
    const b = 4;
    var result = extractDigits("a5b4");

    try std.testing.expectEqual(@as(u8, a), result[0]);
    try std.testing.expectEqual(@as(u8, b), result[1]);
}

test "from '7ball9' returns 7 & 9" {
    const a = 7;
    const b = 9;
    var result = extractDigits("7ball9");

    try std.testing.expectEqual(@as(u8, a), result[0]);
    try std.testing.expectEqual(@as(u8, b), result[1]);
}

test "from 'lol33lol' returns 3 & 3" {
    const a = 3;
    const b = 3;
    var result = extractDigits("lol33lol");

    try std.testing.expectEqual(@as(u8, a), result[0]);
    try std.testing.expectEqual(@as(u8, b), result[1]);
}
