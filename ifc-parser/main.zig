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

pub const ParseDiagnostic = struct {
    message: []const u8,
    location: struct {
        line: u32,
        col: u32,
    },
};

pub const ParseCtx = struct {
    src: []const u8,

    pos: u32,
    line: u32,
    col: u32,

    const Self = @This();

    pub fn start(src: []const u8) Self {
        return Self{
            .src = src,
            .pos = 0,
            .line = 1,
            .col = 1,
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
    }

    pub fn expectAdvance(self: *Self) !u8 {
        return self.advance() orelse error.UnexpectedEof;
    }

    /// advance until the next non-whitespace
    pub fn advanceSkipWs(self: *Self) ?u8 {
        var curr = peekCurrent();

        while (curr != null) : (curr = self.advance()) {
            switch (curr.?) {
                ' ', '\n', '\t' => {
                    continue;
                },
                _ => break,
            }
        }

        return curr;
    }

    pub fn nextTokenSkipWs(self: *Self, token: []const u8) !bool {
        const curr = self.advanceSkipWs();
        if (curr == null) return error.UnexpectedEof;
        return std.mem.eql(u8, self.src[self.pos .. self.pos + token.len], token);
    }

    pub fn expectTerminator(self: *Self, token: []const u8) !void {
        if (!try self.nextTokenSkipWs(";"))
            return error.MissingTerminator;
        try self.consumeToken(";");
    }

    /// consume a token (advance by its length)
    pub fn consumeToken(self: *Self, token: []const u8) !void {
        var i = token.len;
        while (i > 0) : (i -= 1) {
            try self.advance();
        }
    }

    pub fn nextIdentSkipWs(self: *Self) ![]const u8 {
        const first = self.advanceSkipWs();
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
                _ => break,
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

pub const ParseOpts = struct {
    diagnostics: ?*ParseDiagnostic = null,
};

pub const Ifc = struct {
    iso: []const u8,

    header: struct {
        file_description: []const u8,
        file_name: []const u8,
        file_schema: []const u8,

        const Self = @This();

        pub fn parse(ctx: *ParseCtx, opts: ParseOpts) !Self {
            _ = opts;
            if (!try ctx.nextTokenSkipWs("HEADER"))
                return error.MissingHeader;
            ctx.consumeToken("HEADER");
            ctx.expectTerminator();

            if (!try ctx.nextTokenSkipWs("FILE_DESCRIPTION"))
                return error.MissingHeader;
            ctx.consumeToken("FILE");
            ctx.expectTerminator();

            if (!try ctx.nextTokenSkipWs("ENDSEC"))
                return error.MissingHeaderEndSec;
            ctx.consumeToken("ENDSEC");
            ctx.expectTerminator();
        }
    },

    data: struct {
        objects: []const IfcObject,
    },
};

pub const Parser = struct {
    const Self = @This();

    const Line = struct {};

    pub fn init() Self {
        return Self{};
    }

    pub fn parse(self: Self, src: []const u8) void {
        _ = self;
        _ = src;
    }
};

test "geom" {
    const src = try FileBuffer.fromDirAndPath(t.allocator, std.fs.cwd(), "./test/data/test-ifc-1.ifc");
    var parser = Parser.init();
    const result = try parser.parse(src);
    _ = result;
}
