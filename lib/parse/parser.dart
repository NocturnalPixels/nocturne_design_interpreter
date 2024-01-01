import 'package:nocturne_design/lex/token.dart';
import 'package:nocturne_design/parse/expression.dart';
import 'package:nocturne_design/parse/parsing_exception.dart';
import 'package:nocturne_design/parse/statement.dart';

class Parser {
  final List<Token> _tokens;
  int _current;

  Parser(this._tokens): _current = 0;

  List<Statement> parse() {
    List<Statement> statements = [];

    while (!_isEnd()) {
      statements.add(_parseStatement());
    }

    return statements;
  }

  Statement _parseStatement() {
    Statement ret;

    switch (_advance().tokenType) {
      case TokenType.lBrace:
        return _block();

      case TokenType.function:
        return _function();

      case TokenType.ifL:
        return _if();

      case TokenType.constL:
        ret = _declaration(true);
        _consume(TokenType.semicolon, ParsingException(ParsingExceptionType.missingSemicolon, _peek(), "Expected ';' after declaration."));
        break;
      case TokenType.let:
        ret = _declaration(false);
        _consume(TokenType.semicolon, ParsingException(ParsingExceptionType.missingSemicolon, _peek(), "Expected ';' after declaration."));
        break;

      case TokenType.breakL:
        return BreakStatement();
      case TokenType.whileL:
        return _while();
      case TokenType.forL:
        return _for();

      case TokenType.returnL:
        ret = _return();
        _consume(TokenType.semicolon, ParsingException(ParsingExceptionType.missingSemicolon, _peek(), "Expected ';' after return."));
        break;

      case TokenType.identifier:
        ret = _identifier();
        _consume(TokenType.semicolon, ParsingException(ParsingExceptionType.missingSemicolon, _peek(), "Expected ';' after ${_previous().lexeme}."));
        break;

      default:
        throw ParsingException(ParsingExceptionType.undefinedStatement, _previous(), "Unknown Statement");
    }

    return ret;
  }

  Statement _parseStatementNoSemicolon() {
    Statement ret;

    switch (_advance().tokenType) {
      case TokenType.lBrace:
        return _block();

      case TokenType.function:
        return _function();

      case TokenType.ifL:
        return _if();

      case TokenType.constL:
        ret = _declaration(true);
        break;
      case TokenType.let:
        ret = _declaration(false);
        break;

      case TokenType.breakL:
        return BreakStatement();
      case TokenType.whileL:
        return _while();
      case TokenType.forL:
        return _for();

      case TokenType.returnL:
        ret = _return();
        break;

      case TokenType.identifier:
        ret = _identifier();
        break;

      default:
        throw ParsingException(ParsingExceptionType.undefinedStatement, _previous(), "Unknown Statement");
    }

    return ret;
  }

  Statement _identifier() {
    Token name = _previous();

    if (_peek().tokenType == TokenType.equal) {
      return _assign();
    }
    else if (_peek().tokenType == TokenType.lParen) {
      _advance();

      List<Expression> parameters = [];

      if (_peek().tokenType != TokenType.rParen) {
        do {
          parameters.add(_parseExpression());
          _advance();
        } while (_previous().tokenType == TokenType.comma);
      }

      _current--;
      _consume(TokenType.rParen, ParsingException(ParsingExceptionType.missingClosingParentheses, _peek(), "Expected ')' after call parameters."));

      return CallStatement(name, parameters);
    }
    else if (_match([TokenType.plusequal, TokenType.minusequal, TokenType.starequal, TokenType.slashequal])) {
      Token op = switch (_previous().tokenType) {
        TokenType.plusequal => Token(TokenType.plus, -1, "+", "+"),
        TokenType.minusequal => Token(TokenType.minus, -1, "-", "-"),
        TokenType.starequal => Token(TokenType.star, -1, "*", "*"),
        TokenType.slashequal => Token(TokenType.slash, -1, "/", "/"),
        _ => throw ParsingException(ParsingExceptionType.floatingIdentifier, _previous(), "Floating identifier.")
      };
      Expression value = _parseExpression();

      return AssignStatement(name, BinaryExpression(op, VarExpression(name), value));
    }
    else if (_match([TokenType.plusplus, TokenType.minusminus])) {
      Token op = switch (_previous().tokenType) {
        TokenType.plusplus => Token(TokenType.plus, -1, "+", "+"),
        TokenType.minusminus => Token(TokenType.minus, -1, "-", "-"),
        _ => throw ParsingException(ParsingExceptionType.floatingIdentifier, _previous(), "Floating identifier.")
      };
      return AssignStatement(name, BinaryExpression(op, VarExpression(name), LiteralExpression(op, 1)));
    }

    throw ParsingException(ParsingExceptionType.floatingIdentifier, _previous(), "Floating identifier.");
  }

  AssignStatement _assign() {
    Token name = _previous();

    _advance();

    Expression initializer = _parseExpression();
    return AssignStatement(name, initializer);
  }

  BlockStatement _block() {
    Token blame = _previous();

    List<Statement> statements = [];

    while (_peek().tokenType != TokenType.rBrace) {
      statements.add(_parseStatement());
    }

    _advance();

    return BlockStatement(statements, blame);
  }

  DeclarationStatement _declaration(bool isConstant) {
    Token name = _advance();
    Token? type;

    int properties = 0;

    properties |= isConstant ? Properties.constant.value : 0;

    if (_peek().tokenType == TokenType.colon) {
      _advance();

      type = _consume(TokenType.identifier, ParsingException(ParsingExceptionType.missingType, _peek(), "Expected type after ':' in declaration '${name.lexeme}'"));

      if (_peek().tokenType == TokenType.lBracket) {
        _advance();

        _consume(TokenType.rBracket, ParsingException(ParsingExceptionType.missingClosingBracket, _peek(), "Expected ']' to finish array type declaration."));
      }
    }

    Expression? initializer;

    if (_peek().tokenType == TokenType.equal) {
      _advance();
      initializer = _parseExpression();
    }

    return DeclarationStatement(name, type, initializer, properties);
  }

  ForStatement _for() {
    Token blame = _previous();
    _consume(TokenType.lParen, ParsingException(ParsingExceptionType.missingOpeningParentheses, _peek(), "Expected '(' after 'for'."));

    DeclarationStatement initializer = _declaration(false);
    _consume(TokenType.semicolon, ParsingException(ParsingExceptionType.missingSemicolon, _peek(), "Expected ';' after for condition."));
    Expression condition = _parseExpression();
    _consume(TokenType.semicolon, ParsingException(ParsingExceptionType.missingSemicolon, _peek(), "Expected ';' after for condition."));
    Statement accumulator = _parseStatementNoSemicolon();
    _consume(TokenType.rParen, ParsingException(ParsingExceptionType.missingClosingParentheses, _peek(), "Expected ')' after for accumulator."));

    Statement action = _parseStatement();

    return ForStatement(initializer, condition, accumulator, action, blame);
  }

  FunctionStatement _function() {
    Token name = _advance();

    _consume(TokenType.lParen, ParsingException(ParsingExceptionType.missingOpeningParentheses, _peek(), "Expected '(' after function identifier."));

    List<DeclarationStatement> parameters = [];

    if (_peek().tokenType != TokenType.rParen) {
      do {
        parameters.add(_declaration(true));
        _advance();
      } while (_previous().tokenType == TokenType.comma);
    }

    _current--;
    _consume(TokenType.rParen, ParsingException(ParsingExceptionType.missingClosingParentheses, _peek(), "Expected ')' after function parameters."));

    Token? returnType;

    if (_peek().tokenType == TokenType.colon) {
      _advance();

      returnType = _consume(TokenType.identifier, ParsingException(ParsingExceptionType.missingType, _peek(), "Expected type after ':' in function declaration '${name.lexeme}'"));
    }

    return FunctionStatement(name, returnType, parameters, _parseStatement());
  }

  IfStatement _if() {
    Token blame = _previous();

    _consume(TokenType.lParen, ParsingException(ParsingExceptionType.missingOpeningParentheses, _peek(), "Expected '(' after 'if'."));

    Expression condition = _parseExpression();

    _consume(TokenType.rParen, ParsingException(ParsingExceptionType.missingClosingParentheses, _peek(), "Expected ')' after if condition."));

    Statement ifBranch = _parseStatement();
    Statement? elseBranch;

    if (_peek().tokenType == TokenType.elseL) {
      elseBranch = _parseStatement();
    }

    return IfStatement(condition, ifBranch, elseBranch, blame);
  }

  ReturnStatement _return() {
    return ReturnStatement(_previous(), _parseExpression());
  }

  WhileStatement _while() {
    Token blame = _previous();

    _consume(TokenType.lParen, ParsingException(ParsingExceptionType.missingOpeningParentheses, _peek(), "Expected '(' after 'while'."));

    Expression condition = _parseExpression();

    _consume(TokenType.rParen, ParsingException(ParsingExceptionType.missingClosingParentheses, _peek(), "Expected ')' after while condition."));

    Statement action = _parseStatement();

    return WhileStatement(condition, action, blame);
  }

  Expression _parseExpression() {
    return _booleanEquality();
  }

  Expression _booleanEquality() {
    Expression e = _equality();

    while (_match([TokenType.ampamp, TokenType.pipepipe])) {
      Token op = _previous();
      Expression right = _equality();
      e = BinaryExpression(op, e, right);
    }

    return e;
  }

  Expression _equality() {
    Expression e = _comparison();

    while (_match([TokenType.bangequal, TokenType.equalequal])) {
      Token op = _previous();
      Expression right = _comparison();
      e = BinaryExpression(op, e, right);
    }

    return e;
  }

  Expression _comparison() {
    Expression e = _binary();

    while (_match([TokenType.less, TokenType.lessequal, TokenType.greater, TokenType.greaterequal])) {
      Token op = _previous();
      Expression right = _binary();
      e = BinaryExpression(op, e, right);
    }

    return e;
  }

  Expression _binary() {
    Expression e = _term();

    while (_peek().tokenType == TokenType.identifier) {
      Token op = _advance();
      Expression right = _term();
      e = BinaryExpression(op, e, right);
    }

    return e;
  }

  Expression _term() {
    Expression e = _factor();

    while (_match([TokenType.plus, TokenType.minus])) {
      Token op = _previous();
      Expression right = _factor();
      e = BinaryExpression(op, e, right);
    }

    return e;
  }

  Expression _factor() {
    Expression e = _unary();

    while (_match([TokenType.star, TokenType.slash])) {
      Token op = _previous();
      Expression right = _unary();
      e = BinaryExpression(op, e, right);
    }

    return e;
  }

  Expression _unary() {
    while (_match([TokenType.bang, TokenType.minus])) {
      Token op = _previous();
      Expression right = _unary();
      return UnaryExpression(op, right);
    }

    return _literal();
  }

  Expression _literal() {
    if (_peek().tokenType == TokenType.falseL) {
      _advance();
      return LiteralExpression(_peek(), false);
    }
    if (_peek().tokenType == TokenType.trueL) {
      _advance();
      return LiteralExpression(_peek(), true);
    }
    if (_peek().tokenType == TokenType.nullL) {
      _advance();
      return LiteralExpression(_peek(), null);
    }

    if (_match([TokenType.integer, TokenType.real, TokenType.string])) {
      return LiteralExpression(_previous(), _previous().tokenValue);
    }

    if (_peek().tokenType == TokenType.identifier) {
      return _identifierExpression();
    }

    if (_peek().tokenType == TokenType.lParen) {
      Expression e = _parseExpression();
      _consume(TokenType.rParen, ParsingException(ParsingExceptionType.missingClosingParentheses, _peek(), "Expected ')' after grouping."));
      return GroupingExpression(e);
    }

    throw ParsingException(ParsingExceptionType.uncaughtToken, _peek(), "Uncaught token.");
  }

  Expression _identifierExpression() {
    Token name = _advance();

    if (_peek().tokenType == TokenType.equal) {
      _advance();

      Expression initializer = _parseExpression();
      return AssignExpression(name, initializer);
    }
    else if (_peek().tokenType == TokenType.lParen) {
      _advance();

      List<Expression> params = [];

      if (_peek().tokenType != TokenType.rParen) {
        do {
          params.add(_parseExpression());
          _advance();
        } while (_previous().tokenType == TokenType.comma);
      }

      _current--;
      _consume(TokenType.rParen, ParsingException(ParsingExceptionType.missingClosingParentheses, _peek(), "Expected ')' after call parameters."));

      return CallExpression(name, params);
    }
    else {
      return VarExpression(name);
    }
  }

  bool _isEnd() => _peek().tokenType == TokenType.eof;

  Token _previous() => _tokens[_current - 1];
  Token _peek() => _tokens[_current];
  Token _advance() {
    if (_isEnd()) return _previous();
    return _tokens[_current++];
  }

  Token _consume(TokenType type, ParsingException exception) {
    if (_peek().tokenType == type) return _advance();

    throw exception;
  }

  bool _match(List<TokenType> types) {
    for (TokenType type in types) {
      if (_peek().tokenType == type) {
        _advance();
        return true;
      }
    }

    return false;
  }
}