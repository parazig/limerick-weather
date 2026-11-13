const std = @import("std");
const weathermap = @import("limerick_weather");

// Open-Meteo API configuration for Limerick, Ireland
// Latitude: 52.6638 N, Longitude: -8.6267 W (west of Greenwich, hence the minus)
const openMeteoUrl = "https://api.open-meteo.com/v1/forecast";
const openMeteoLat = "52.6638";
const openMeteoLon = "-8.6267";
const openMeteoParams = "&hourly=temperature_2m,weathercode,wind_speed_10m,wind_direction_10m&forecast_hours=24&timezone=Europe%2FDublin";

// JSON Structures for Open-Meteo API
const HourlyForecast = struct {
    time: []const []const u8,
    temperature_2m: []const f64,
    weathercode: []const i32,
    wind_speed_10m: []const f64,
    wind_direction_10m: []const f64,
};

const WeatherResponse = struct {
    latitude: f64,
    longitude: f64,
    timezone: []const u8,
    hourly: HourlyForecast,
};

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
    var gpa = std.heap.SafeAllocator.init(std.heap.page_allocator, .{});
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const weather = try fetchWeather(allocator, io);
    defer weather.deinit();

    const stdout_file = std.Io.File.stdout();
    var stdout_buf: [4096]u8 = undefined;
    var out = stdout_file.writer(io, &stdout_buf);

    try out.interface.print("Limerick, Ireland - Next 24 Hours Forecast\n", .{});
    try out.interface.print("========================================\n", .{});

    const hourly = weather.value.hourly;
    const count = @min(hourly.time.len, 24);

    var i: usize = 0;
    while (i < count) : (i += 1) {
        const temp = hourly.temperature_2m[i];
        const code = hourly.weathercode[i];
        const info = weathermap.getWeatherInfo(code);
        const time_str = hourly.time[i];
        const local_time = if (time_str.len >= 16) time_str[11..16] else time_str;
        const wind_kmh = hourly.wind_speed_10m[i];
        const wind_dir = weathermap.windDirectionToCompass(hourly.wind_direction_10m[i]);

        try out.interface.print("{s} {d:5.1}°C {d:4.0} km/h {s: >3} {s} {s}\n", .{
            local_time,
            temp,
            wind_kmh,
            wind_dir,
            info.emoji,
            info.condition,
        });
    }

    try out.interface.flush();
}
