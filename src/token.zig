const std = @import("std");
const testing = std.testing;

pub const Token = struct {
    type: TokenType,
    literal: []const u8,
    fileName: [:0]const u8,
    lineNumber: u32,
    colNumber: u8,
};

pub const TokenType = enum {
    ILLEGAL,
    EOF,

    // Identifiers and literals
    IDENT,
    INT,

    // Operators
    ASSIGN,
    PLUS,
    MINUS,
    BANG,
    ASTERISK,
    SLASH,

    LT,
    LTE,
    GT,
    GTE,
    EQ,
    NEQ,

    // DELIMITERS
    COMMA,

    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,

    // Keywords
    FN,
    VAR,
    CONST,
    RETURN,
    TRUE,
    FALSE,
    IF,
    ELSE
};

pub const keywords = std.StaticStringMap(TokenType).initComptime(.{
    .{"fn", .FN},
    .{"const", .CONST},
    .{"var", .VAR},
    .{"return", .RETURN},
    .{"true", .TRUE},
    .{"false", .FALSE},
    .{"if", .IF},
    .{"else", .ELSE},
    .{"=", .ASSIGN},
    .{"+", .PLUS},
    .{"-", .MINUS},
    .{"/", .SLASH},
    .{"*", .ASTERISK},
    .{"!", .BANG},
    .{"==", .EQ},
    .{"!=", .NEQ},
    .{">", .GT},
    .{">=", .GTE},
    .{"<", .LT},
    .{"<=", .LTE},
    .{",", .COMMA},
    .{"(", .LPAREN},
    .{")", .RPAREN},
    .{"{", .LBRACE},
    .{"}", .RBRACE},
});

pub fn lookupIdent(ident: []const u8) TokenType {
    const keyword = keywords.get(ident);
    return keyword orelse return .IDENT;
}
