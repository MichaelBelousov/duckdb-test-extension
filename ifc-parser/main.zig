const std = @import("std");
const t = std.testing;
const builtin = @import("builtin");
const json = std.json;
const FileBuffer = @import("./FileBuffer.zig");

pub fn main(args: []const []const u8) void {
    std.debug.assert(args.len >= 2);
    const file = args[1];
    const src = try FileBuffer.fromDirAndPath(t.allocator, std.fs.cwd(), file);
    // defer free
}

// TODO: generate types from object model

pub const IfcObject = struct {
    id: u32,
    type_name: []const u8,
    references: []const u8,
};

pub const Ifc = struct {
    iso: []const u8,
    header: struct {
    },
    objects: []const IfcObject,
};

pub const Parser = struct {
    const Self = @This();

    pub fn init() Self {
        return Self {};
    }

    pub fn parse(self: Self, src: []const u8) void {
    }
};

test "geom" {
    const src = try FileBuffer.fromDirAndPath(t.allocator, std.fs.cwd(), "./test/data/test-ifc-1.ifc");
    var parser = Parser.init();
    const result = try parser.parse(src);
}
