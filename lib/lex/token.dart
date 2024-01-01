enum TokenType {
  lParen, rParen, lBracket, rBracket, lBrace, rBrace,

  colon, semicolon, dot, comma,

  plus, plusplus, minus, minusminus, star, slash,

  plusequal, minusequal, starequal, slashequal,

  equal, bang, ampersand, pipe,

  equalequal, bangequal, less, lessequal, greater, greaterequal,

  ampamp, pipepipe,

  integer, real, string,

  constL, function, let, whileL, forL, breakL, returnL, struct, mod,

  trueL, falseL, nullL,

  ifL, elseL,

  identifier,

  eof
}

class Token {
  final TokenType tokenType;
  final int line;
  final String lexeme;
  final dynamic tokenValue;

  const Token(this.tokenType, this.line, this.lexeme, this.tokenValue);

  @override
  String toString() => "$tokenType | $lexeme | $tokenValue | $line";
}