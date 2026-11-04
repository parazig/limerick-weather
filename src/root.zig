//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

/// This is a documentation comment to explain the `printAnotherMessage` function below.
///
/// Accepting an `Io.Writer` instance is a handy way to write reusable code.
pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
    try writer.print("Run `zig build test` to run the tests.\n", .{});
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}


test "test weather code range and specific mappings" {
    // Test specific weather codes
    try std.testing.expect(getEmojiForCode(0) == "☀️");
    try std.testing.expect(getEmojiForCode(2) == "🌤️");
    try std.testing.expect(getEmojiForCode(80) == "🌧️");
    try std.testing.expect(getEmojiForCode(71) == "❄️");
    try std.testing.expect(getEmojiForCode(96) == "🌩️");
    // Test the fallback case for an unmapped code (e.g., 100)
    try std.testing.expect(getEmojiForCode(100) == "☀️"); 
}

test "test getWeatherInfo consistency" {
    // This test ensures that for a known code (e.g., 2 - Cloudy), 
    // the name and emoji are correctly paired.
    const code = 2;
    const (name, emoji) = getWeatherInfo(code);
    try std.testing.expect(name.ptr != null);
    try std.testing.expect(emoji.ptr != null);
    try std.testing.expect(std.mem.eql(u8, name, "clouds"));
    try std.testing.expect(std.mem.eql(u8, emoji, "🌤️"));
}

