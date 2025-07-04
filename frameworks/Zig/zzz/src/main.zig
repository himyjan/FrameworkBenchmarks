const std = @import("std");
const builtin = @import("builtin");
const zzz = @import("zzz");
const http = zzz.HTTP;
const tardy = zzz.tardy;
const Tardy = tardy.Tardy(.auto);
const Runtime = tardy.Runtime;
const Socket = tardy.Socket;
const Server = http.Server;
const Router = http.Router;
const Context = http.Context;
const Route = http.Route;
const Respond = http.Respond;

const Message = struct { message: []const u8 };
var date: [29]u8 = undefined;

pub fn main() !void {
    const host: []const u8 = "0.0.0.0";
    const port: u16 = 8080;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const allocator, const is_debug = switch (builtin.mode) {
        .Debug, .ReleaseSafe => .{ gpa.allocator(), true },
        .ReleaseSmall, .ReleaseFast => .{ std.heap.smp_allocator, false },
    };

    defer {
        if (is_debug and gpa.deinit() == .leak) {
            @panic("Memory leak has occurred!");
        }
    }

    var t = try Tardy.init(allocator, .{
        .threading = .all,
    });
    defer t.deinit();

    var router = try Router.init(allocator, &.{
        Route.init("/plaintext").get({}, homeHandler).layer(),
        Route.init("/json").get({}, jsonHandler).layer(),
    }, .{});
    defer router.deinit(allocator);

    var socket = try Socket.init(.{ .tcp = .{ .host = host, .port = port } });
    defer socket.close_blocking();
    try socket.bind();
    try socket.listen(4096);

    const EntryParams = struct {
        router: *const Router,
        socket: Socket,
    };

    try t.entry(
        EntryParams{ .router = &router, .socket = socket },
        struct {
            fn entry(rt: *Runtime, p: EntryParams) !void {
                if (rt.id == 0) try rt.spawn(.{rt}, updateDate, 1024 * 1024 * 4);
                var server = Server.init(.{
                    .capture_count_max = 0,
                });
                try server.serve(rt, p.router, .{ .normal = p.socket });
            }
        }.entry,
    );
}

pub fn homeHandler(ctx: *const Context, _: void) !Respond {
    return ctx.response.apply(.{
        .mime = http.Mime.TEXT,
        .body = "Hello, World!",
        .status = .OK,
        .headers = &.{
            .{ "Date", try ctx.allocator.dupe(u8, date[0..]) },
        },
    });
}

pub fn jsonHandler(ctx: *const Context, _: void) !Respond {
    return ctx.response.apply(.{
        .mime = http.Mime.JSON,
        .body = try std.json.stringifyAlloc(ctx.allocator, Message{ .message = "Hello, World!" }, .{}),
        .status = .OK,
        .headers = &.{
            .{ "Date", try ctx.allocator.dupe(u8, date[0..]) },
        },
    });
}

pub fn updateDate(rt: *Runtime) !void {
    const format = std.fmt.comptimePrint(
        "{s}, {s} {s} {s} {s}:{s}:{s} GMT",
        .{
            "{[day_name]s}",
            "{[day]d:0>2}",
            "{[month]s}",
            "{[year]d}",
            "{[hour]d:0>2}",
            "{[minute]d:0>2}",
            "{[second]d:0>2}",
        },
    );
    while (true) {
        var d = http.Date.init(std.time.timestamp());

        const http_date = d.to_http_date();

        _ = try std.fmt.bufPrint(&date, format, http_date);

        try tardy.Timer.delay(rt, .{ .nanos = std.time.ns_per_ms * 900 });
    }
}
