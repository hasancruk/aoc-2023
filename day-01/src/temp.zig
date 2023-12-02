// Copied from Zig Discord for validation. Solution by snek_case.
const std = @import("std");
const input = @embedFile("part-1.txt");
pub fn main() void {
    var line_it = std.mem.tokenizeAny(u8, input, "\n");
    var sum: u32 = 0;
    while (line_it.next()) |line| {
        var digits: [2]?u8 = .{ null, null }; //0 to 9
        var digits_i: u1 = 0;
        next_digit: for (0..line.len) |i| {
            if (std.ascii.isDigit(line[i])) {
                digits[digits_i] = line[i] - '0';
                digits_i |= 1;
                continue;
            }
            for ([_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" }, 1..) |num_str, d| {
                if (i + num_str.len - 1 < line.len and std.mem.eql(u8, line[i .. i + num_str.len], num_str)) {
                    digits[digits_i] = @intCast(d);
                    digits_i |= 1;
                    continue :next_digit;
                }
            }
        }
        std.debug.assert(digits[0] != null);
        sum += @as(u32, @intCast(digits[0].?)) * 10;
        sum += if (digits[1]) |d1| d1 else digits[0].?;

        std.debug.print("{s} : ({?d},{?d})\n", .{ line, digits[0], digits[1] });
    }
    std.debug.print("{}\n", .{sum});
}
