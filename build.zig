const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const shared = b.option(bool, "shared", "Build shared library") orelse false;

    const enable_tls = b.option(enum { none, mbedtls, openssl_1_0, openssl_1_1 }, "tls", "Enable TLS") orelse .none;
    const enable_cgi = b.option(bool, "cgi", "Enable CGI") orelse false;
    const enable_caching = b.option(bool, "caching", "Enable caching") orelse false;
    const disable_http2 = b.option(bool, "no_http2", "Disable http2") orelse true;

    if (enable_tls != .none) @panic("TODO: unsupported tls option");
    if (!disable_http2 and enable_tls == .none) @panic("http2 requires tls");

    const target_os: []const u8 =
        switch (target.result.os.tag) {
        .windows => "WIN32",
        .linux => "LINUX",
        else => |tag| if (tag.isDarwin()) "OSX" else if (tag.isBSD()) "BSD" else @panic("unsupported target"),
    };

    const lib = std.Build.Step.Compile.create(b, .{
        .name = "civetweb",
        .kind = .lib,
        .linkage = if (shared) .dynamic else .static,
        .root_module = .{
            .target = target,
            .optimize = optimize,
        },
    });
    lib.defineCMacro(if (optimize == .Debug) "DEBUG" else "NDEBUG", null);
    lib.defineCMacro(target_os, null);
    lib.defineCMacro("USE_STACK_SIZE", "102400");
    lib.defineCMacro("USE_IPV6", null);
    lib.defineCMacro(switch (enable_tls) {
        .none => "NO_SSL",
        .mbedtls => "USE_MBEDTLS",
        .openssl_1_0 => "OPENSSL_API_1_0",
        .openssl_1_1 => "OPENSSL_API_1_1",
    }, null);
    if (!enable_cgi) lib.defineCMacro("NO_CGI", null);
    if (!enable_caching) lib.defineCMacro("NO_CACHING", null);
    if (!disable_http2) lib.defineCMacro("USE_HTTP2", null);
    lib.addIncludePath(.{ .path = "include" });
    lib.addCSourceFiles(.{ .files = &.{"src/civetweb.c"}, .flags = &.{} });
    lib.linkLibC();

    lib.installHeader("include/civetweb.h", "civetweb.h");
    b.installArtifact(lib);
}
