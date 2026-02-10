const std = @import("std");
const Token = @import("tokens.zig").Token;
const TokenType = @import("tokens.zig").TokenType;
const Literal = @import("tokens.zig").Literal;
const root_error = @import("main.zig").root_error;

pub const Scanner = struct {
    source: []const u8,
    tokens: std.ArrayListUnmanaged(Token) = .{},

    start: usize = 0,
    current: usize = 0,
    line: usize = 1,

    var keywords: std.StringHashMap(TokenType) = undefined;

    pub fn init(source: []const u8) Scanner {
        return .{
            .source = source,
            .tokens = .{},
        };
    }

    pub fn initKeywords(self: *Scanner, allocator: std.mem.Allocator) !void {
        _ = self;

        keywords = std.StringHashMap(TokenType).init(allocator);

        try keywords.put("and", .AND);
        try keywords.put("class", .CLASS);
        try keywords.put("else", .ELSE);
        try keywords.put("false", .FALSE);
        try keywords.put("for", .FOR);
        try keywords.put("fun", .FUN);
        try keywords.put("if", .IF);
        try keywords.put("nil", .NIL);
        try keywords.put("or", .OR);
        try keywords.put("print", .PRINT);
        try keywords.put("return", .RETURN);
        try keywords.put("super", .SUPER);
        try keywords.put("this", .THIS);
        try keywords.put("true", .TRUE);
        try keywords.put("var", .VAR);
        try keywords.put("while", .WHILE);
    }

    pub fn scanTokens(self: *Scanner, allocator: std.mem.Allocator) ![]Token {
        while (!self.isAtEnd()) {
            // We are at the beginning of the next lexeme.
            self.start = self.current;
            try self.scanToken(allocator);
        }

        try self.tokens.append(allocator, Token.init(
            .EOF,
            "",
            null,
            self.line,
        ));

        return self.tokens.items;
    }

    fn scanToken(self: *Scanner, allocator: std.mem.Allocator) !void {
        const c = self.advance();
        switch (c) {
            // --- single-character tokens ---
            '(' => try self.addToken(allocator, .LEFT_PAREN),
            ')' => try self.addToken(allocator, .RIGHT_PAREN),
            '{' => try self.addToken(allocator, .LEFT_BRACE),
            '}' => try self.addToken(allocator, .RIGHT_BRACE),
            ',' => try self.addToken(allocator, .COMMA),
            '.' => try self.addToken(allocator, .DOT),
            '-' => try self.addToken(allocator, .MINUS),
            '+' => try self.addToken(allocator, .PLUS),
            ';' => try self.addToken(allocator, .SEMICOLON),
            '*' => try self.addToken(allocator, .STAR),

            // --- operators ---
            '!' => try self.addToken(
                allocator,
                if (self.match('=')) .BANG_EQUAL else .BANG,
            ),

            '=' => try self.addToken(
                allocator,
                if (self.match('=')) .EQUAL_EQUAL else .EQUAL,
            ),

            '<' => try self.addToken(
                allocator,
                if (self.match('=')) .LESS_EQUAL else .LESS,
            ),

            '>' => try self.addToken(
                allocator,
                if (self.match('=')) .GREATER_EQUAL else .GREATER,
            ),

            // --- comments or slash ---
            '/' => {
                if (self.match('/')) {
                    // A comment goes until the end of the line.
                    while (self.peek() != '\n' and !self.isAtEnd()) {
                        _ = self.advance();
                    }
                } else {
                    try self.addToken(allocator, .SLASH);
                }
            },

            // --- whitespace (ignored) ---
            ' ', '\r', '\t' => {},

            // --- newline ---
            '\n' => {
                self.line += 1;
            },

            // -- string literals --
            '"' => {
                try self.string(allocator);
            },

            else => if (isDigit(c)) {
                try self.number(allocator);
            } else if (isAlpha(c)) {
                try self.identifier(allocator);
            } else {
                try root_error(self.line, "Unexpected character.");
            }, // ignore for now

        }
    }

    fn identifier(self: *Scanner, allocator: std.mem.Allocator) !void {
        // Initalize keywords map
        try self.initKeywords(allocator);

        while (isAlphaNumeric(self.peek())) {
            _ = self.advance();
        }

        const text = self.source[self.start..self.current];

        const maybe_type = keywords.get(text);

        const token_type = if (maybe_type) |t| t else .IDENTIFIER;

        try self.addToken(allocator, token_type);
    }

    fn number(self: *Scanner, allocator: std.mem.Allocator) !void {
        while (isDigit(self.peek())) {
            _ = self.advance();
        }

        // Look for a fractional part.
        if (self.peek() == '.' and isDigit(self.peekNext())) {
            // Consume the "."
            _ = self.advance();

            while (isDigit(self.peek())) {
                _ = self.advance();
            }
        }

        const text = self.source[self.start..self.current];
        const value = try std.fmt.parseFloat(f64, text);

        try self.addTokenLiteral(
            allocator,
            .NUMBER,
            .{ .number = value },
        );
    }

    fn string(self: *Scanner, allocator: std.mem.Allocator) !void {
        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') {
                self.line += 1;
            }
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            try root_error(self.line, "Unterminated string");
            return;
        }

        // The closing ".
        _ = self.advance();

        // Trim the surrounding quotes.
        const value = self.source[self.start + 1 .. self.current - 1];
        try self.addTokenLiteral(
            allocator,
            .STRING,
            .{ .string = value },
        );
    }

    fn match(self: *Scanner, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;

        self.current += 1;
        return true;
    }

    fn peek(self: *Scanner) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn peekNext(self: *Scanner) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn isAlpha(c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
    }

    fn isAlphaNumeric(c: u8) bool {
        return isAlpha(c) or isDigit(c);
    }

    fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn isAtEnd(self: *Scanner) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Scanner) u8 {
        const c = self.source[self.current];
        self.current += 1;
        return c;
    }

    fn addToken(self: *Scanner, allocator: std.mem.Allocator, token_type: TokenType) !void {
        try self.addTokenLiteral(allocator, token_type, null);
    }

    fn addTokenLiteral(
        self: *Scanner,
        allocator: std.mem.Allocator,
        token_type: TokenType,
        literal: ?Literal,
    ) !void {
        const text = self.source[self.start..self.current];

        try self.tokens.append(allocator, Token.init(
            token_type,
            text,
            literal,
            self.line,
        ));
    }
};

// 4.6.1 String literals
