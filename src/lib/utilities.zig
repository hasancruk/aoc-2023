const std = @import("std");
const Wyhash = std.hash.Wyhash;
const autoHasStrat = std.hash.autoHashStrat;
const Strategy = std.hash.Strategy;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const test_allocator = std.testing.allocator;

fn concatDigits(digits: []u8) u32 {
    var len: u32 = @as(u32, @intCast(digits.len)) - 1;
    var factor = std.math.pow(u32, 10, len);
    var result: u32 = 0;

    for (digits) |digit| {
        result += @as(u32, digit) * factor;
        factor /= 10;
    }

    return result;
}

pub fn hash(key: anytype) [16]u8 {
    var hasher = Wyhash.init(0);
    autoHasStrat(&hasher, key, Strategy.Deep);
    return std.Build.hex64(hasher.final());
}

pub fn sumList(comptime T: type, list: ArrayList(T)) u32 {
    var sum: u32 = 0;

    for (list.items) |n| {
        sum += n;
    }

    return sum;
}

pub fn parseString(string: []const u8, delimiter: u8, allocator: Allocator) ![][]const u8 {
    var list = ArrayList([]const u8).init(allocator);
    var iter = std.mem.splitScalar(u8, string, delimiter);
    while (iter.next()) |str| {
        try list.append(str);
    }
    return list.toOwnedSlice();
}

pub fn charToDigit(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        else => c,
    };
}

pub fn isDigit(c: u8) bool {
    return charToDigit(c) < 10;
}

test "hash struct" {
    var point = .{
        .x = @as(u8, 23),
        .y = @as(u8, 2),
    };

    var result = hash(point);
    var expected = "ed33ab0277e2e3df";

    try std.testing.expect(std.mem.eql(u8, &result, expected));
}

test "hash string" {
    var result = hash("hello");
    var expected = "2f36ea6f91d174cf";

    try std.testing.expect(std.mem.eql(u8, &result, expected));
}

test "concatDigits [2] to '2'" {
    var expected: u32 = 2;
    var input = [_]u8{2};
    var result = concatDigits(&input);

    try std.testing.expectEqual(result, expected);
}

test "concatDigits [1, 2, 3, 4] to '1234'" {
    var expected: u32 = 1234;
    var input = [_]u8{ 1, 2, 3, 4 };
    var result = concatDigits(&input);

    try std.testing.expectEqual(result, expected);
}

test "concatDigits [5, 2, 3] to '523'" {
    var expected: u32 = 523;
    var input = [_]u8{ 5, 2, 3 };
    var result = concatDigits(&input);

    try std.testing.expectEqual(result, expected);
}
