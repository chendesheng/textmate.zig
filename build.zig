const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const c_onig = onigModule(b, target, optimize);
    const onig = b.addModule("oniguruma", .{
        .root_source_file = b.path("src/pkg/oniguruma/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    onig.addImport("c_onig", c_onig);

    const lib_mod = b.addModule("textmate", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport("oniguruma", onig);

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "textmate",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    const unit_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    unit_mod.addImport("oniguruma", onig);
    const unit_tests = b.addTest(.{ .root_module = unit_mod });
    const run_unit_tests = b.addRunArtifact(unit_tests);

    const tests_mod = b.createModule(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests_mod.addImport("textmate_lib", lib_mod);
    const tests_exe = b.addExecutable(.{ .name = "tests", .root_module = tests_mod });
    const run_tests = b.addRunArtifact(tests_exe);

    const specs_mod = b.createModule(.{
        .root_source_file = b.path("src/test_specs.zig"),
        .target = target,
        .optimize = optimize,
    });
    specs_mod.addImport("textmate_lib", lib_mod);
    const specs_exe = b.addExecutable(.{ .name = "test_specs", .root_module = specs_mod });
    const run_specs = b.addRunArtifact(specs_exe);

    const test_step = b.step("test", "Run all textmate tests");
    test_step.dependOn(&run_unit_tests.step);
    test_step.dependOn(&run_tests.step);
    test_step.dependOn(&run_specs.step);

    const tests_step = b.step("tests", "Run serialize/deserialize tests");
    tests_step.dependOn(&run_tests.step);
    const specs_step = b.step("specs", "Run textmate grammar spec tests");
    specs_step.dependOn(&run_specs.step);
}

fn onigModule(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.Optimize) *std.Build.Module {
    const translate = b.addTranslateC(.{
        .root_source_file = b.path("src/pkg/oniguruma/oniguruma.h"),
        .target = target,
        .optimize = optimize,
    });
    translate.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    const module = translate.createModule();
    module.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    module.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    module.linkSystemLibrary("onig", .{});
    return module;
}
