const std = @import("std");

fn createNewModule(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.OptimizeMode,
    name: []const u8,
    sourcePath: []const u8,
    comptime short: []const u8,
) !void {
    const exe = b.addExecutable(.{
        .name = name,
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = sourcePath },
        .target = target,
        .optimize = optimize,
    });

    const utilities = b.addModule("utilities", .{ .source_file = .{ .path = "src/lib/utilities.zig" } });
    exe.addModule("utilities", utilities);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    var shortTrimmed: [short.len]u8 = undefined;
    @memcpy(&shortTrimmed, short[0..short.len]);
    std.mem.replaceScalar(u8, &shortTrimmed, ' ', 0);

    var runCmdBuf: [100]u8 = undefined;
    const runCmd = try std.fmt.bufPrint(runCmdBuf[0..], "run:{s}", .{shortTrimmed});

    var runDescBuf: [100]u8 = undefined;
    const runDescription = try std.fmt.bufPrint(runDescBuf[0..], " Run {s}", .{short});

    var testCmdBuf: [100]u8 = undefined;
    const testCmd = try std.fmt.bufPrint(testCmdBuf[0..], "test:{s}", .{shortTrimmed});

    var testDescBuf: [100]u8 = undefined;
    const testDescription = try std.fmt.bufPrint(testDescBuf[0..], " Run {s} unit tests", .{short});

    const run_step = b.step(runCmd, runDescription);
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = sourcePath },
        .target = target,
        .optimize = optimize,
    });

    unit_tests.addModule("utilities", utilities);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step(testCmd, testDescription);
    test_step.dependOn(&run_unit_tests.step);
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "aoc-2023",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const exe_01 = b.addExecutable(.{
        .name = "aoc-2023-day-01",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/day-01/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const exe_02 = b.addExecutable(.{
        .name = "aoc-2023-day-02",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/day-02/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const utilities = b.addModule("utilities", .{ .source_file = .{ .path = "src/lib/utilities.zig" } });
    exe.addModule("utilities", utilities);
    exe_01.addModule("utilities", utilities);
    exe_02.addModule("utilities", utilities);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);
    b.installArtifact(exe_01);
    b.installArtifact(exe_02);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);
    const run_01_cmd = b.addRunArtifact(exe_01);
    const run_02_cmd = b.addRunArtifact(exe_02);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());
    run_01_cmd.step.dependOn(b.getInstallStep());
    run_02_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
        run_01_cmd.addArgs(args);
        run_02_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_01_step = b.step("run:day01", "Run day 01");
    run_01_step.dependOn(&run_01_cmd.step);

    const run_02_step = b.step("run:day02", "Run day 02");
    run_02_step.dependOn(&run_02_cmd.step);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    unit_tests.addModule("utilities", utilities);

    const unit_tests_01 = b.addTest(.{
        .root_source_file = .{ .path = "src/day-01/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    unit_tests_01.addModule("utilities", utilities);

    const unit_tests_02 = b.addTest(.{
        .root_source_file = .{ .path = "src/day-02/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    unit_tests_02.addModule("utilities", utilities);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const run_unit_tests_01 = b.addRunArtifact(unit_tests_01);
    const run_unit_tests_02 = b.addRunArtifact(unit_tests_02);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    const test_step_01 = b.step("test:day01", "Run day 01 unit tests");
    const test_step_02 = b.step("test:day02", "Run day 02 unit tests");
    test_step.dependOn(&run_unit_tests.step);
    test_step_01.dependOn(&run_unit_tests_01.step);
    test_step_02.dependOn(&run_unit_tests_02.step);

    try createNewModule(
        b,
        target,
        optimize,
        "aoc-2023-day-03",
        "src/day-03/main.zig",
        "day 03",
    );
}