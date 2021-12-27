const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("ringbuffer", "src/lib.zig");
    lib.setBuildMode(mode);
    lib.install();

    var main_tests = b.addTest("src/lib.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);


    const example_step = b.step("examples", "Build examples");

    var examples_dir = try std.fs.cwd().openDir("example/", .{ .iterate = true });
    var examples_dir_iterator = examples_dir.iterate();

    while (try examples_dir_iterator.next()) |example_file| {
        if (example_file.kind != .File) continue;

        const ext = std.fs.path.extension(example_file.name);
        if (!std.mem.eql(u8, ext, ".zig")) continue;

        const basename = std.fs.path.basename(example_file.name);
        
        var example = b.addExecutable(basename[0..basename.len - ".zig".len], b.fmt("example/{s}", .{ example_file.name }));
        example.setBuildMode(mode);
        example.addPackage(.{
            .name = "ringbuffer",
            .path = .{ .path = "src/lib.zig" },
        });
        example.setOutputDir("zig-out/examples");

        example_step.dependOn(&example.step);
    }
}
