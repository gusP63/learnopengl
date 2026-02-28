const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "learnopengl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const modules = [_]*std.Build.Step.Compile{exe};

    for (modules) |e| {
        e.root_module.addIncludePath(.{ .cwd_relative = "vendored/include" });
        e.root_module.addCSourceFile(.{ .file = .{ .cwd_relative = "vendored/src/glad.c" }, .flags = &[_][]const u8{"-std=c99"} });

        e.linkSystemLibrary("SDL3");
        e.linkSystemLibrary("opengl");
        e.linkLibC();
        b.installArtifact(e);
    }

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
