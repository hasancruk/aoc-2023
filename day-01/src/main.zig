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

fn extractDigits(text: []const u8) [2]u8 {
    var isFirst = true;
    var result: [2]u8 = undefined;
    var last: u8 = undefined;
    var hasLast = false;

    for (text) |c| {
        var digit = charToDigit(c);
        if (digit < 10) {
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
