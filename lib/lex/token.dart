enum TokenType {
  lParen, rParen, lBracket, rBracket, lBrace, rBrace,

  colon, semicolon, dot, comma,

  integer, real, string,

  constL, function, let,

  trueL, falseL, nullL,

  identifier,

  eof
}

class Token {
  TokenType tokenType;
  int line;
  String lexeme;
  dynamic tokenValue;

  Token(this.tokenType, this.line, this.lexeme, this.tokenValue);

  @override
  String toString() => "$tokenType | $lexeme | $tokenValue | $line";
}