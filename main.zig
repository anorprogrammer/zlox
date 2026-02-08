const std = @import("std");

const hadError = false;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len > 2) {
        std.debug.print("Usage: zlox [script]\n", .{});
        std.process.exit(64);
    } else if (args.len == 2) {
        try runFile(allocator, args[1]);
    } else {
        try runPrompt(allocator);
    }
}

fn runFile(allocator: std.mem.Allocator, path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(source);

    try run(allocator, source);

    if (hadError) std.process.exit(65);
}

fn runPrompt(allocator: std.mem.Allocator) !void {
    var stdin_buffer: [10]u8 = undefined;
    var stdin: std.fs.File = std.fs.File.stdin();
    var stdin_reader: std.fs.File.Reader = stdin.reader(&stdin_buffer);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer: std.fs.File.Writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout: *std.Io.Writer = &stdout_writer.interface;

    var alloc = std.heap.DebugAllocator(.{}).init;
    defer _ = alloc.deinit();
    const da = alloc.allocator();

    var allocating_writer = std.Io.Writer.Allocating.init(da);
    defer allocating_writer.deinit();

    while (true) {
        try stdout.writeAll("\n> ");
        try stdout.flush();

        _ = stdin_reader.interface.streamDelimiter(&allocating_writer.writer, '\n') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        const line = allocating_writer.written();
        try run(allocator, line);
        hadError = false;

        allocating_writer.clearRetainingCapacity(); // empty the line buffer
        stdin_reader.interface.toss(1); // skip the newline
    }
}

fn run(allocator: std.mem.Allocator, source: []const u8) !void {
    _ = allocator;

    // NOTE: this should be implemented

    std.debug.print("\nYou wrote: {s}\n", .{source});
}

// ---- Error handling functions ----

fn report(line: u32, where: []const u8, message: []const u8) !void {
    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer: std.fs.File.Writer = std.fs.File.stdout().writer(&stderr_buffer);
    const stderr: *std.Io.Writer = &stderr_writer.interface;

    _ = stderr.print("[line {d}] Error{a}: {a}\n", .{ line, where, message });
    hadError = true;
}

fn _error(line: u32, message: []const u8) void {
    try report(line, "", message);
}
