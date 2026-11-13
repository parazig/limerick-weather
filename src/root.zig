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

/// Sixteen compass points, indexed by `round(degrees / 22.5) % 16`.
const compass_points = [_][]const u8{
    "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
    "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW",
};

/// Map an Open-Meteo wind direction (degrees from true north) to the nearest
/// of sixteen compass points. Any value is normalized into `[0, 360)` first, so
/// negative or over-360 inputs are handled.
pub fn windDirectionToCompass(degrees: f64) []const u8 {
    const normalized = @mod(degrees, 360.0);
    const index = @as(usize, @intFromFloat(@round(normalized / 22.5))) % compass_points.len;
    return compass_points[index];
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

test "windDirectionToCompass maps 16 compass points" {
    try std.testing.expectEqualStrings("N", windDirectionToCompass(0));
    try std.testing.expectEqualStrings("N", windDirectionToCompass(359));
    try std.testing.expectEqualStrings("N", windDirectionToCompass(-1));
    try std.testing.expectEqualStrings("NNE", windDirectionToCompass(22.5));
    try std.testing.expectEqualStrings("NE", windDirectionToCompass(45));
    try std.testing.expectEqualStrings("ENE", windDirectionToCompass(67.5));
    try std.testing.expectEqualStrings("E", windDirectionToCompass(90));
    try std.testing.expectEqualStrings("ESE", windDirectionToCompass(112.5));
    try std.testing.expectEqualStrings("SE", windDirectionToCompass(135));
    try std.testing.expectEqualStrings("SSE", windDirectionToCompass(157.5));
    try std.testing.expectEqualStrings("S", windDirectionToCompass(180));
    try std.testing.expectEqualStrings("SSW", windDirectionToCompass(202.5));
    try std.testing.expectEqualStrings("SW", windDirectionToCompass(225));
    try std.testing.expectEqualStrings("WSW", windDirectionToCompass(247.5));
    try std.testing.expectEqualStrings("W", windDirectionToCompass(270));
    try std.testing.expectEqualStrings("WNW", windDirectionToCompass(292.5));
    try std.testing.expectEqualStrings("NW", windDirectionToCompass(315));
    try std.testing.expectEqualStrings("NNW", windDirectionToCompass(337.5));
    // Values wrap past 360 without changing the result.
    try std.testing.expectEqualStrings("E", windDirectionToCompass(90 + 360));
}
