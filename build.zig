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

    var iso_step = b.step("iso", "build ISO file for Zernel 2");
    const iso_command = b.addSystemCommand(&[_][]const u8{"./commands/build_iso.sh"});
    iso_command.step.dependOn(&kernel.step);
    iso_step.dependOn(&iso_command.step);

    var run_step = b.step("run", "run Zernel 2 in QEMU");
    const run_command = b.addSystemCommand(&[_][]const u8{"./commands/run.sh"});
    run_command.step.dependOn(iso_step);
    run_step.dependOn(&run_command.step);

    var debug_step = b.step("debug", "debug Zernel 2 in GDB");
    const debug_command = b.addSystemCommand(&[_][]const u8{"./commands/debug.sh"});
    debug_step.dependOn(&debug_command.step);
}
