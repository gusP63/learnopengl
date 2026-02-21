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

    const ex5_8 = b.addExecutable(.{
        .name = "ex5_8",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/5_8.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const modules = [_]*std.Build.Step.Compile{ exe, ex5_8 };

    for (modules) |e| {
        e.root_module.addIncludePath(.{ .cwd_relative = "vendored/include" });
        e.root_module.addCSourceFile(.{ .file = .{ .cwd_relative = "vendored/src/glad.c" }, .flags = &[_][]const u8{"-std=c99"} });

        e.linkSystemLibrary("SDL3");
        e.linkSystemLibrary("opengl");
        e.linkLibC();
        b.installArtifact(e);
    }

    // exe.root_module.addIncludePath(.{ .cwd_relative = "vendored/include" });
    // exe.root_module.addCSourceFile(.{ .file = .{ .cwd_relative = "vendored/src/glad.c" }, .flags = &[_][]const u8{"-std=c99"} });
    //
    // exe.linkSystemLibrary("SDL3");
    // exe.linkSystemLibrary("opengl");
    // exe.linkLibC();
    // b.installArtifact(exe);
    //
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    const run_step_5 = b.step("run_5", "Run ex x");
    const run_cmd_5 = b.addRunArtifact(ex5_8);
    run_step_5.dependOn(&run_cmd_5.step);
    run_cmd_5.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
