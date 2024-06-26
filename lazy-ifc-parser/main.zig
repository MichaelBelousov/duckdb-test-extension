const std = @import("std");
const t = std.testing;
const builtin = @import("builtin");
const json = std.json;
const FileBuffer = @import("./FileBuffer.zig");
const Loc = @import("./loc.zig").Loc;
const SpacePrint = @import("./loc.zig").SpacePrint;

pub fn cliMain(argc: u32, argv: []const u8) void {
    std.debug.assert(argc >= 2);
    const file_path = argv[1];

    const file = try FileBuffer.fromDirAndPath(t.allocator, std.fs.cwd(), file_path);
    defer file.free(t.allocator);

    const ctx = ParseCtx.start("UT_LinearPlacement_1.ifc", file.buffer);
    const parsed = Ifc.parse(&ctx, .{});
    _ = parsed;
}

// TODO: generate types from object model

pub const IfcObject = struct {
    id: u32,
    type_name: []const u8,
    references: []const u8,
};

const ParseDiagnostic = struct {
    message: []const u8 = "",

    // FIXME: share this data with context somehow
    loc: Loc = .{},
    src: []const u8 = "",

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = fmt;
        // FIXME: this only works when the diagnostics are a private field
        try writer.print(
            \\{s}
            \\ at {}
            \\  | {s}
            \\    {}^
            \\
        , .{ self.message, self.loc, try self.loc.containing_line(self.src), SpacePrint.init(self.loc.col - 1) });
    }
};

pub const ParseCtx = struct {
    src_name: []const u8 = "UNKNOWN SOURCE",
    src: []const u8,

    // TODO: use loc instead
    pos: u32,
    line: u32,
    col: u32,

    diagnostics: ParseDiagnostic,

    const Self = @This();

    pub fn as_loc(self: Self) Loc {
        return Loc{
            .line = self.line,
            .col = self.col,
            .index = self.pos,
            .source_ref = self.src_name,
        };
    }

    pub fn start(name: []const u8, src: []const u8) Self {
        return Self{
            .src_name = name,
            .src = src,
            .pos = 0,
            .line = 1,
            .col = 1,
            .diagnostics = .{},
        };
    }

    pub fn advance(self: *Self) ?u8 {
        const result = self.peekCurrent();

        if (result == '\n') {
            self.col = 0;
            self.line +|= 1;
        }

        self.col +|= 1;
        self.pos +|= 1;

        return result;
    }

    pub fn expectAdvance(self: *Self) !u8 {
        return self.advance() orelse error.UnexpectedEof;
    }

    /// advance until the next (or current) non-whitespace
    pub fn skipWs(self: *Self) ?u8 {
        var curr = self.peekCurrent();

        while (curr != null and switch (curr.?) {
            ' ', '\n', '\t' => true,
            else => false,
        }) : (curr = self.advance()) {}

        return curr;
    }

    pub fn nextTokenSkipWs(self: *Self, token: []const u8) !bool {
        const curr = self.skipWs();
        if (curr == null) {
            return error.UnexpectedEof;
        }
        return std.mem.eql(u8, self.src[self.pos .. self.pos + token.len], token);
    }

    pub fn expectTerminator(self: *Self) !void {
        if (!try self.nextTokenSkipWs(";"))
            return error.MissingTerminator;
        try self.consumeToken(";");
    }

    /// consume a known token (advance by its length)
    /// use nextTokenSkipWs to confirm it first
    pub fn consumeToken(self: *Self, token: []const u8) !void {
        var i = token.len;
        while (i > 0) : (i -= 1) {
            _ = try self.expectAdvance();
        }
    }

    pub fn nextIdentSkipWs(self: *Self) ![]const u8 {
        const first = self.skipWs();
        const first_pos = self.pos;

        if (first == null)
            return error.UnexpectedEof;

        var curr = first.?;

        while (true) : (curr = try self.expectAdvance()) {
            switch (curr) {
                'a'...'z',
                'A'...'Z',
                '0'...'9',
                '_',
                => {
                    continue;
                },
                else => break,
            }
        }

        const ident = self.src[first_pos..self.pos];

        return ident;
    }

    pub const Element = struct {
        name: []const u8,
        //args: []const Expr,
    };

    /// an  element is like:
    /// ELEMNAME(arg1, arg2)
    pub fn parseElement(self: *ParseCtx) !Element {
        const ident = self.nextIdentSkipWs();
        _ = ident;
        try self.expectTerminator();
    }

    pub fn parseExpr(self: *Self, token: []const u8) !void {
        var i = token.len;
        while (i > 0) : (i -= 1) {
            self.advance();
        }
    }

    /// 0 is the current
    pub fn peek(self: *Self, offset: u32) ?u8 {
        return if (self.pos + offset < self.src.len)
            self.src[self.pos + offset]
        else
            null;
    }

    pub fn peekCurrent(self: *Self) ?u8 {
        return self.peek(0);
    }
};

pub const ParseOpts = struct {};

pub const Ifc = struct {
    const Header = struct {
        file_description: []const u8,
        file_name: []const u8,
        file_schema: []const u8,

        pub fn parse(ctx: *ParseCtx, opts: ParseOpts) !Header {
            _ = opts;

            if (!try ctx.nextTokenSkipWs("HEADER"))
                return error.MissingHeader;
            try ctx.consumeToken("HEADER");
            try ctx.expectTerminator();

            // FIXME: this should be an element parse
            if (!try ctx.nextTokenSkipWs("FILE_DESCRIPTION"))
                return error.MissingFileDescription;
            try ctx.consumeToken("FILE_DESCRIPTION");
            try ctx.expectTerminator();

            if (!try ctx.nextTokenSkipWs("ENDSEC"))
                return error.MissingHeaderEndSec;
            try ctx.consumeToken("ENDSEC");
            try ctx.expectTerminator();

            return Header{
                .file_description = "",
                .file_name = "",
                .file_schema = "",
            };
        }
    };

    iso: []const u8,
    header: Header,
    data: struct {
        objects: []const IfcObject,
    },

    const Self = @This();

    pub fn parse(ctx: *ParseCtx, opts: ParseOpts) !Self {
        // FIXME: need to better control the parse entry point
        // so that it's more self contained that diagnostics must be set up
        errdefer |e| {
            ctx.diagnostics.message = @errorName(e);
            ctx.diagnostics.loc = ctx.as_loc();
            ctx.diagnostics.src = ctx.src;
            std.debug.print("{}", .{ctx.diagnostics});
            std.debug.print("{s}", .{ctx.src[ctx.pos .. ctx.pos + 4]});
            std.debug.print("\n", .{});
        }

        const isoToken = "ISO-10303-21";
        if (!try ctx.nextTokenSkipWs(isoToken))
            return error.BadIsoDeclaration;
        try ctx.consumeToken(isoToken);
        try ctx.expectTerminator();

        std.debug.print("{s}", .{ctx.src[ctx.pos .. ctx.pos + 4]});
        std.debug.print("\n", .{});

        const header = try Header.parse(ctx, opts);

        return Self{
            .iso = isoToken,
            .header = header,
            .data = .{
                .objects = &.{},
            },
        };
    }
};

test "geom" {
    const file = try FileBuffer.fromDirAndPath(t.allocator, std.fs.cwd(), "./test/data/UT_LinearPlacement_1.ifc");
    defer file.free(t.allocator);
    var ctx = ParseCtx.start("UT_LinearPlacement_1.ifc", file.buffer);
    const ifc = try Ifc.parse(&ctx, .{});

    try t.expectEqualStrings(ifc.header.file_name, "./test/data/UT_LinearPlacement_1.ifc");
}
