const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "image-in-zig",
        .root_source_file = .{ .path = "src/Image.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const example_exe = b.addExecutable(.{
        .name = "image-in-zig",
        .root_source_file = .{ .path = "src/examples.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(example_exe);

    const run_cmd = b.addRunArtifact(example_exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run examples");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/Image.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
