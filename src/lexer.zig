const std = @import("std");
const token = @import("token.zig");

const Lexer = struct {
    input: [:0]const u8,
    position: u32,
    readPosition: u32,
    ch: u8,

    fn init(input: [:0]const u8) Lexer {
        var lexer = Lexer{
            .input = input,
            .position = 0,
            .readPosition = 0,
            .ch = 0
        };

        lexer.readChar();
        return lexer;
    }

    fn readChar(self: *Lexer) void {
        if (self.readPosition >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.readPosition];
        }

        self.position = self.readPosition;
        self.readPosition += 1;
    }

    fn peekChar(self: *Lexer) u8 {
        if (self.readPosition >= self.input.len) {
            return 0;
        } else {
            return self.input[self.readPosition];
        }
    }

    fn readIdentifier(self: *Lexer) []const u8 {
        const position = self.position;
        while (isLetter(self.ch)) {
            self.readChar();
        }
        return self.input[position..self.position];
    }

    fn readNumber(self: *Lexer) []const u8 {
        const position = self.position;
        while (isDigit(self.ch)) {
            self.readChar();
        }
        return self.input[position..self.position];
    }

    fn skipWhitespace(self: *Lexer) void {
        while (self.ch == ' ' or self.ch == '\t' or self.ch == '\n' or self.ch == '\r') {
            self.readChar();
        }
    }

    fn nextToken(self: *Lexer) token.Token {
        self.skipWhitespace();

        const tok = switch (self.ch) {
            '=' => blk: {
                if (self.peekChar() == '=') {
                    self.readChar();
                    break :blk newToken(.EQ, self.input[self.position-1..self.readPosition]);
                } else {
                    break :blk newToken(.ASSIGN, self.input[self.position..self.readPosition]);
                }
            },
            '!' => blk: {
                if (self.peekChar() == '=') {
                    self.readChar();
                    break :blk newToken(.NEQ, self.input[self.position-1..self.readPosition]);
                } else {
                    break: blk newToken(.BANG, self.input[self.position..self.readPosition]);
                }
            },
            '<' => blk: {
                if (self.peekChar() == '=') {
                    self.readChar();
                    break :blk newToken(.LTE, self.input[self.position-1..self.readPosition]);
                } else {
                    break: blk newToken(.LT, self.input[self.position..self.readPosition]);
                }
            },
            '>' => blk: {
                if (self.peekChar() == '=') {
                    self.readChar();
                    break :blk newToken(.GTE, self.input[self.position-1..self.readPosition]);
                } else {
                    break: blk newToken(.GT, self.input[self.position..self.readPosition]);
                }
            },
            '(' => newToken(.LPAREN, self.input[self.position..self.readPosition]),
            ')' => newToken(.RPAREN, self.input[self.position..self.readPosition]),
            '{' => newToken(.LBRACE, self.input[self.position..self.readPosition]),
            '}' => newToken(.RBRACE, self.input[self.position..self.readPosition]),
            ',' => newToken(.COMMA, self.input[self.position..self.readPosition]),
            '+' => newToken(.PLUS, self.input[self.position..self.readPosition]),
            '-' => newToken(.MINUS, self.input[self.position..self.readPosition]),
            '/' => newToken(.SLASH, self.input[self.position..self.readPosition]),
            '*' => newToken(.ASTERISK, self.input[self.position..self.readPosition]),
            0 => newToken(.EOF, ""),
            else => blk: {
                if (isLetter(self.ch)) {
                    const literal = self.readIdentifier();
                    return newToken(token.lookupIdent(literal), literal);
                } else if (isDigit(self.ch)) {
                    return newToken(.INT, self.readNumber());
                } else {
                    break :blk newToken(.ILLEGAL, self.input[self.position..self.readPosition]);
                }
            }
        };

        self.readChar();
        return tok;
    }
};

fn newToken(tokenType: token.TokenType, tokenLiteral: []const u8) token.Token {
    return token.Token{
        .type = tokenType,
        .literal = tokenLiteral,
        .fileName = "",
        .lineNumber = 0,
        .colNumber = 0
    };
}

fn isLetter(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or (ch == '_');
}

fn isDigit(ch: u8) bool {
    return (ch >= '0') and (ch <= '9');
}

test "text nextToken" {
    const input =
        \\const five = 5
        \\const ten = 10
        \\
        \\fn add(a, b) {
        \\  return a + b
        \\}
        \\
        \\const result = add(five, ten)
        \\
        \\!-/*5
        \\5 < 10 > 5
        \\
        \\if (5 < 10) {
        \\  return true
        \\} else {
        \\  return false
        \\}
        \\
        \\10 == 10
        \\10 != 10
        \\10 <= 10
        \\10 >= 10
    ;

    const Expected = struct {
        expectedType: token.TokenType,
        expectedLiteral: [:0]const u8
    };

    const tests = [_]Expected{
        .{.expectedType = .CONST, .expectedLiteral = "const"},
        .{.expectedType = .IDENT, .expectedLiteral = "five"},
        .{.expectedType = .ASSIGN, .expectedLiteral = "="},
        .{.expectedType = .INT, .expectedLiteral = "5"},
        .{.expectedType = .CONST, .expectedLiteral = "const"},
        .{.expectedType = .IDENT, .expectedLiteral = "ten"},
        .{.expectedType = .ASSIGN, .expectedLiteral = "="},
        .{.expectedType = .INT, .expectedLiteral = "10"},
        .{.expectedType = .FN, .expectedLiteral = "fn"},
        .{.expectedType = .IDENT, .expectedLiteral = "add"},
        .{.expectedType = .LPAREN, .expectedLiteral = "("},
        .{.expectedType = .IDENT, .expectedLiteral = "a"},
        .{.expectedType = .COMMA, .expectedLiteral = ","},
        .{.expectedType = .IDENT, .expectedLiteral = "b"},
        .{.expectedType = .RPAREN, .expectedLiteral = ")"},
        .{.expectedType = .LBRACE, .expectedLiteral = "{"},
        .{.expectedType = .RETURN, .expectedLiteral = "return"},
        .{.expectedType = .IDENT, .expectedLiteral = "a"},
        .{.expectedType = .PLUS, .expectedLiteral = "+"},
        .{.expectedType = .IDENT, .expectedLiteral = "b"},
        .{.expectedType = .RBRACE, .expectedLiteral = "}"},
        .{.expectedType = .CONST, .expectedLiteral = "const"},
        .{.expectedType = .IDENT, .expectedLiteral = "result"},
        .{.expectedType = .ASSIGN, .expectedLiteral = "="},
        .{.expectedType = .IDENT, .expectedLiteral = "add"},
        .{.expectedType = .LPAREN, .expectedLiteral = "("},
        .{.expectedType = .IDENT, .expectedLiteral = "five"},
        .{.expectedType = .COMMA, .expectedLiteral = ","},
        .{.expectedType = .IDENT, .expectedLiteral = "ten"},
        .{.expectedType = .RPAREN, .expectedLiteral = ")"},
        .{.expectedType = .BANG, .expectedLiteral = "!"},
        .{.expectedType = .MINUS, .expectedLiteral = "-"},
        .{.expectedType = .SLASH, .expectedLiteral = "/"},
        .{.expectedType = .ASTERISK, .expectedLiteral = "*"},
        .{.expectedType = .INT, .expectedLiteral = "5"},
        .{.expectedType = .INT, .expectedLiteral = "5"},
        .{.expectedType = .LT, .expectedLiteral = "<"},
        .{.expectedType = .INT, .expectedLiteral = "10"},
        .{.expectedType = .GT, .expectedLiteral = ">"},
        .{.expectedType = .INT, .expectedLiteral = "5"},
        .{.expectedType = .IF, .expectedLiteral = "if"},
        .{.expectedType = .LPAREN, .expectedLiteral = "("},
        .{.expectedType = .INT, .expectedLiteral = "5"},
        .{.expectedType = .LT, .expectedLiteral = "<"},
        .{.expectedType = .INT, .expectedLiteral = "10"},
        .{.expectedType = .RPAREN, .expectedLiteral = ")"},
        .{.expectedType = .LBRACE, .expectedLiteral = "{"},
        .{.expectedType = .RETURN, .expectedLiteral = "return"},
        .{.expectedType = .TRUE, .expectedLiteral = "true"},
        .{.expectedType = .RBRACE, .expectedLiteral = "}"},
        .{.expectedType = .ELSE, .expectedLiteral = "else"},
        .{.expectedType = .LBRACE, .expectedLiteral = "{"},
        .{.expectedType = .RETURN, .expectedLiteral = "return"},
        .{.expectedType = .FALSE, .expectedLiteral = "false"},
        .{.expectedType = .RBRACE, .expectedLiteral = "}"},
        .{.expectedType = .INT, .expectedLiteral = "10"},
        .{.expectedType = .EQ, .expectedLiteral = "=="},
        .{.expectedType = .INT, .expectedLiteral = "10"},
        .{.expectedType = .INT, .expectedLiteral = "10"},
        .{.expectedType = .NEQ, .expectedLiteral = "!="},
        .{.expectedType = .INT, .expectedLiteral = "10"},
        .{.expectedType = .INT, .expectedLiteral = "10"},
        .{.expectedType = .LTE, .expectedLiteral = "<="},
        .{.expectedType = .INT, .expectedLiteral = "10"},
        .{.expectedType = .INT, .expectedLiteral = "10"},
        .{.expectedType = .GTE, .expectedLiteral = ">="},
        .{.expectedType = .INT, .expectedLiteral = "10"},
    };

    var lexer = Lexer.init(input);

    for (tests) |value| {
        const tok = lexer.nextToken();

        errdefer std.debug.print("Test fail: Expected {s} - {s}, Got {s} {s}\n", .{value.expectedLiteral, @tagName(value.expectedType), tok.literal, @tagName(tok.type)});
        try std.testing.expect(tok.type == value.expectedType);
        try std.testing.expect(std.mem.eql(u8, tok.literal, value.expectedLiteral));
    }

}
