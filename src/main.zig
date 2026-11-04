const std = @import("std");

// Open-Meteo API configuration for Limerick, Ireland
// Latitude: ~52.5, Longitude: ~8.3
const openMeteoUrl = "https://api.open-meteo.com/v1/forecast";
const openMeteoLat = "52.5";
const openMeteoLon = "8.3";
const openMeteoParams = "&hourly=temperature_2m,weathercode&forecast_hours=12&timezone=Europe%2FLondon";

// JSON Structures for Open-Meteo API
const HourlyForecast = struct {
    time: []const []const u8,
    temperature_2m: []const f64,
    weathercode: []const i32,
};

const WeatherResponse = struct {
    latitude: f64,
    longitude: f64,
    timezone: []const u8,
    hourly: HourlyForecast,
};

// Weather code mapping from Open-Meteo to conditions and emoji
const WeatherInfo = struct {
    code: i32,
    condition: []const u8,
    emoji: []const u8,
};

const weatherCodes = [_]WeatherInfo{
    .{ .code = 0, .condition = "clear", .emoji = "☀️" },
    .{ .code = 1, .condition = "clear", .emoji = "☀️" },
    .{ .code = 2, .condition = "clouds", .emoji = "🌤️" },
    .{ .code = 3, .condition = "clouds", .emoji = "🌤️" },
    .{ .code = 51, .condition = "rain", .emoji = "🌧️" },
    .{ .code = 61, .condition = "rain", .emoji = "🌧️" },
    .{ .code = 71, .condition = "snow", .emoji = "❄️" },
    .{ .code = 80, .condition = "rain", .emoji = "🌧️" },
    .{ .code = 95, .condition = "thunderstorm", .emoji = "🌩️" },
    .{ .code = 96, .condition = "thunderstorm", .emoji = "🌩️" },
    .{ .code = 99, .condition = "thunderstorm", .emoji = "🌩️" },
};

fn getWeatherInfo(code: i32) WeatherInfo {
    for (weatherCodes) |info| {
        if (info.code == code) {
            return info;
        }
    }
    return WeatherInfo{ .code = 0, .condition = "clear", .emoji = "☀️" };
}

fn fetchWeather(allocator: std.mem.Allocator, io: std.Io) !std.json.Parsed(WeatherResponse) {
    var client: std.http.Client = .{ .allocator = allocator, .io = io };
    defer client.deinit();

    const url = openMeteoUrl ++ "?latitude=" ++ openMeteoLat ++ "&longitude=" ++ openMeteoLon ++ openMeteoParams;

    var body = std.Io.Writer.Allocating.init(allocator);
    defer body.deinit();

    const response = try client.fetch(.{
        .location = .{ .url = url },
        .response_writer = &body.writer,
    });

    if (response.status != .ok) {
        std.debug.print("HTTP Error: {any}\n", .{response.status});
        return error.HttpError;
    }

    const body_slice = body.writer.buffer[0..body.writer.end];
    return try std.json.parseFromSlice(WeatherResponse, allocator, body_slice, .{
        .ignore_unknown_fields = true,
        .allocate = .alloc_always,
    });
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const weather = try fetchWeather(allocator, io);
    defer weather.deinit();

    std.debug.print("Limerick, Ireland - Next 12 Hours Forecast\n", .{});
    std.debug.print("========================================\n", .{});

    const hourly = weather.value.hourly;
    const count = @min(hourly.time.len, 12);

    var i: usize = 0;
    while (i < count) : (i += 1) {
        const temp = hourly.temperature_2m[i];
        const code = hourly.weathercode[i];
        const info = getWeatherInfo(code);
        const time_str = hourly.time[i];
        const local_time = if (time_str.len >= 16) time_str[11..16] else time_str;

        std.debug.print("{s} - {d:.1}°C - {s} {s}\n", .{
            local_time,
            temp,
            info.condition,
            info.emoji,
        });
    }

    std.debug.print("\nWeather emojis: ☀️ 🌤️ 🌧️ 🌨️ 🌩️\n", .{});
}
