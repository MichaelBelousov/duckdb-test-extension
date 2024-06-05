const std = @import("std");
const CrossTarget = std.zig.CrossTarget;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const native_lib = b.addStaticLibrary(.{
        .name = "ifc-parser",
        .root_source_file = .{ .path = "main.zig" },
        .target = target,
        .optimize = optimize,
    });
    //native_lib.force_pic = true;
    b.installArtifact(native_lib);

    const test_filter = b.option([]const u8, "test-filter", "filter for test subcommand");
    const main_tests = b.addTest(.{ .root_source_file = .{ .path = "main.zig" }, .target = target, .optimize = optimize, .filter = test_filter });
    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
