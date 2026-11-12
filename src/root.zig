//! By convention, root.zig is the root source file when making a package.
//!
//! This module is the library surface of the project: it exposes the
//! Open-Meteo weather-code mapping consumed by the CLI in `main.zig`.
const std = @import("std");

/// Open-Meteo weather code mapped to a human-readable condition and emoji.
pub const WeatherInfo = struct {
    code: i32,
    condition: []const u8,
    emoji: []const u8,
};

/// Open-Meteo weather code -> condition + emoji mapping.
pub const weatherCodes = [_]WeatherInfo{
    .{ .code = 0, .condition = "clear", .emoji = "☀️" },
    .{ .code = 1, .condition = "mostly clear", .emoji = "🌤️" },
    .{ .code = 2, .condition = "partly cloudy", .emoji = "⛅" },
    .{ .code = 3, .condition = "overcast", .emoji = "☁️" },
    .{ .code = 45, .condition = "fog", .emoji = "🌫️" },
    .{ .code = 48, .condition = "rime fog", .emoji = "🌫️" },
    .{ .code = 51, .condition = "light drizzle", .emoji = "🌦️" },
    .{ .code = 53, .condition = "drizzle", .emoji = "🌦️" },
    .{ .code = 55, .condition = "dense drizzle", .emoji = "🌧️" },
    .{ .code = 56, .condition = "light freezing drizzle", .emoji = "🌨️" },
    .{ .code = 57, .condition = "freezing drizzle", .emoji = "🌨️" },
    .{ .code = 61, .condition = "light rain", .emoji = "🌦️" },
    .{ .code = 63, .condition = "rain", .emoji = "🌧️" },
    .{ .code = 65, .condition = "heavy rain", .emoji = "🌧️" },
    .{ .code = 66, .condition = "light freezing rain", .emoji = "🌨️" },
    .{ .code = 67, .condition = "freezing rain", .emoji = "🌨️" },
    .{ .code = 71, .condition = "light snow", .emoji = "🌨️" },
    .{ .code = 73, .condition = "snow", .emoji = "❄️" },
    .{ .code = 75, .condition = "heavy snow", .emoji = "❄️" },
    .{ .code = 77, .condition = "snow grains", .emoji = "❄️" },
    .{ .code = 80, .condition = "light rain showers", .emoji = "🌦️" },
    .{ .code = 81, .condition = "rain showers", .emoji = "🌧️" },
    .{ .code = 82, .condition = "violent rain showers", .emoji = "⛈️" },
    .{ .code = 85, .condition = "light snow showers", .emoji = "🌨️" },
    .{ .code = 86, .condition = "snow showers", .emoji = "❄️" },
    .{ .code = 95, .condition = "thunderstorm", .emoji = "⛈️" },
    .{ .code = 96, .condition = "thunderstorm with light hail", .emoji = "⛈️" },
    .{ .code = 99, .condition = "thunderstorm with heavy hail", .emoji = "⛈️" },
};

/// Look up the condition and emoji for an Open-Meteo weather code.
///
/// Unknown codes are reported as "unknown condition" (❓) rather than being
/// mistaken for clear weather.
pub fn getWeatherInfo(code: i32) WeatherInfo {
    for (weatherCodes) |info| {
        if (info.code == code) {
            return info;
        }
    }
    return WeatherInfo{ .code = code, .condition = "unknown condition", .emoji = "❓" };
}

/// Convenience accessor returning just the emoji for a weather code.
pub fn getEmojiForCode(code: i32) []const u8 {
    return getWeatherInfo(code).emoji;
}

test "getEmojiForCode maps known codes" {
    try std.testing.expectEqualStrings("☀️", getEmojiForCode(0));
    try std.testing.expectEqualStrings("⛅", getEmojiForCode(2));
    try std.testing.expectEqualStrings("🌦️", getEmojiForCode(80));
    try std.testing.expectEqualStrings("🌨️", getEmojiForCode(71));
    try std.testing.expectEqualStrings("⛈️", getEmojiForCode(96));
}

test "getEmojiForCode falls back for unknown codes" {
    try std.testing.expectEqualStrings("❓", getEmojiForCode(100));
}

test "getWeatherInfo returns paired condition and emoji" {
    const info = getWeatherInfo(2);
    try std.testing.expectEqualStrings("partly cloudy", info.condition);
    try std.testing.expectEqualStrings("⛅", info.emoji);
}
