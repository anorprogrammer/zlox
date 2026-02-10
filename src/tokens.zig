const std = @import("std");

pub const TokenType = enum {
    // Single-character tokens.
    LEFT_PAREN, // ------> (
    RIGHT_PAREN, // -----> )
    LEFT_BRACE, // ------> {
    RIGHT_BRACE, // -----> }
    COMMA, // -----------> ,
    DOT, // -------------> .
    MINUS, // -----------> -
    PLUS, // ------------> +
    SEMICOLON, // -------> ;
    SLASH, // -----------> /
    STAR, // ------------> *

    // One or two character tokens.
    BANG, // ------------> !
    BANG_EQUAL, // ------> !=
    EQUAL, // -----------> =
    EQUAL_EQUAL, // -----> ==
    GREATER, // ---------> >
    GREATER_EQUAL, // ---> >=
    LESS, // ------------> <
    LESS_EQUAL, // ------> <=

    // Literals.
    IDENTIFIER, // ------> names like variables, functions
    STRING, // ----------> string literal
    NUMBER, // ----------> numeric literal

    // Keywords.
    AND, // -------------> 'and'
    CLASS, // -----------> 'class'
    ELSE, // ------------> 'else'
    FALSE, // -----------> 'false'
    FUN, // -------------> 'fun'
    FOR, // -------------> 'for'
    IF, // --------------> 'if'
    NIL, // -------------> 'nil'
    OR, // --------------> 'or'
    PRINT, // -----------> 'print'
    RETURN, // ----------> 'return'
    SUPER, // -----------> 'super'
    THIS, // ------------> 'this'
    TRUE, // ------------> 'true'
    VAR, // -------------> 'var'
    WHILE, // -----------> 'while'

    // End of file.
    EOF, // -------------> end of input
};

/// Literal values in lox
pub const Literal = union(enum) {
    number: f64,
    string: []const u8,
    boolean: bool,
    nil,
};

pub const Token = struct {
    token_type: TokenType,
    lexeme: []const u8,
    literal: ?Literal,
    line: usize,

    pub fn init(
        token_type: TokenType,
        lexeme: []const u8,
        literal: ?Literal,
        line: usize,
    ) Token {
        return .{
            .token_type = token_type,
            .lexeme = lexeme,
            .literal = literal,
            .line = line,
        };
    }

    pub fn toString(
        token: *const Token,
        allocator: std.mem.Allocator,
    ) ![]u8 {
        return std.fmt.allocPrint(
            allocator,
            "{s} {s} {any}",
            .{
                @tagName(token.token_type),
                token.lexeme,
                token.literal,
            },
        );
    }
};
