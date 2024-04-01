const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.resolveTargetQuery(std.zig.CrossTarget{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    const limine_package = b.dependency("limine-zig", .{});
    const limine_module = limine_package.module("limine");

    const kernel = b.addExecutable(.{
        .code_model = .kernel,
        .name = "zernel2",
        .optimize = optimize,
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
    });

    kernel.linker_script = .{ .path = "linker.ld" };
    kernel.root_module.addImport("limine", limine_module);
    kernel.pie = false;

    b.installArtifact(kernel);
}
