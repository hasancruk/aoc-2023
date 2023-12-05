const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const test_allocator = std.testing.allocator;

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
