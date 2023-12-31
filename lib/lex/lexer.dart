import 'lexing_exception.dart';
import 'token.dart';

class Lexer {
  static const Map<String, TokenType> _keywords = {
    "fn": TokenType.function,
    "let": TokenType.let,
    "const": TokenType.constL,
    "true": TokenType.trueL,
    "false": TokenType.falseL,
    "null": TokenType.nullL,
    "if": TokenType.ifL,
    "else": TokenType.elseL,
    "while": TokenType.whileL,
    "for": TokenType.forL,
    "break": TokenType.breakL,
    "return": TokenType.returnL
  };

  final String _content;
  int _line;
  int _current;

  Lexer(this._content): _line = 1, _current = 0;

  List<Token> lex() {
    List<Token> tokens = [];

    while (!_atEnd()) {
      switch (_advance()) {
        case ' ':
        case '\r':
        case '\t':
          break;
        
        case '\n':
          _line++;
          break;

        case '(':
          tokens.add(Token(TokenType.lParen, _line, "(", null));
          break;
        case ')':
          tokens.add(Token(TokenType.rParen, _line, ")", null));
          break;

        case '{':
          tokens.add(Token(TokenType.lBrace, _line, "{", null));
          break;
        case '}':
          tokens.add(Token(TokenType.rBrace, _line, "}", null));
          break;
        
        case '[':
          tokens.add(Token(TokenType.lBracket, _line, "[", null));
          break;
        case ']':
          tokens.add(Token(TokenType.rBracket, _line, "]", null));
          break;

        case '.':
          tokens.add(Token(TokenType.dot, _line, ".", null));
          break;
        case ',':
          tokens.add(Token(TokenType.comma, _line, ",", null));
          break;
        case ':':
          tokens.add(Token(TokenType.colon, _line, ":", null));
          break;
        case ';':
          tokens.add(Token(TokenType.semicolon, _line, ";", null));
          break;

        case '"':
          tokens.add(_lexString());
          break;

        case '+':
          if (_peek() == "=") {
            _advance();
            tokens.add(Token(TokenType.plusequal, _line, "+=", null));
            break;
          }
          else if (_peek() == '+') {
            _advance();
            tokens.add(Token(TokenType.plusplus, _line, "++", null));
            break;
          }

          tokens.add(Token(TokenType.plus, _line, "+", null));
          break;
        case '-':
          if (_peek() == "=") {
            _advance();
            tokens.add(Token(TokenType.minusequal, _line, "-=", null));
            break;
          }
          else if (_peek() == '-') {
            _advance();
            tokens.add(Token(TokenType.minusminus, _line, "--", null));
            break;
          }

          tokens.add(Token(TokenType.minus, _line, "-", null));
          break;
        case '*':
          if (_peek() == "=") {
            _advance();
            tokens.add(Token(TokenType.starequal, _line, "*=", null));
            break;
          }

          tokens.add(Token(TokenType.star, _line, "*", null));
          break;
        case '/':
          if (_peek() == "/") {
            while (_peek() != "\n" && !_atEnd()) {
              _advance();
            }
            break;
          }
          else if (_peek() == "*") {
            _advance();
            while (_advance() != "*" && _peek() != "/") {
              if (_peek() == '\n') {
                _line++;
              }
            }

            _advance();
            break;
          }
          else if (_peek() == "=") {
            _advance();
            tokens.add(Token(TokenType.slashequal, _line, "/=", null));
            break;
          }

          tokens.add(Token(TokenType.slash, _line, "/", null));
          break;

        case '=':
          if (_peek() == "=") {
            _advance();
            tokens.add(Token(TokenType.equalequal, _line, "==", null));
            break;
          }

          tokens.add(Token(TokenType.equal, _line, "=", null));
          break;
        case '!':
          if (_peek() == "=") {
            _advance();
            tokens.add(Token(TokenType.bangequal, _line, "!=", null));
            break;
          }

          tokens.add(Token(TokenType.bang, _line, "!", null));
          break;

        case '<':
          if (_peek() == "=") {
            _advance();
            tokens.add(Token(TokenType.lessequal, _line, "<=", null));
            break;
          }

          tokens.add(Token(TokenType.less, _line, "<", null));
          break;

        case '>':
          if (_peek() == "=") {
            _advance();
            tokens.add(Token(TokenType.greaterequal, _line, ">=", null));
            break;
          }

          tokens.add(Token(TokenType.greater, _line, ">", null));
          break;
        
        case '&':
          if (_peek() == "&") {
            _advance();
            tokens.add(Token(TokenType.ampamp, _line, "&&", null));
            break;
          }

          tokens.add(Token(TokenType.ampersand, _line, "&", null));
          break;
        case '|':
          if (_peek() == "|") {
            _advance();
            tokens.add(Token(TokenType.pipepipe, _line, "||", null));
            break;
          }

          tokens.add(Token(TokenType.pipe, _line, "|", null));
          break;

        default:
          if (_isNumeric(_previous())) {
            tokens.add(_lexNumber());
            break;
          }

          tokens.add(_lexIdentifier());

          break;
      }
    }

    tokens.add(Token(TokenType.eof, _line, "<EoF>", null));
    return tokens;
  }

  Token _lexString() {
    String value = "";

    while (_peek() != '"') {
      value += _advance();
    }

    _advance();

    return Token(TokenType.string, _line, value, value);
  }

  Token _lexNumber() {
    String value = _previous();
    bool isDecimal = false;

    while (_isNumeric(_peek())) {
      value += _advance();
    }

    if (_peek() == '.') {
      isDecimal = true;
      while (_isNumeric(_peek())) {
        value += _advance();
      }
    }

    return isDecimal ? Token(TokenType.real, _line, value, double.parse(value)) : Token(TokenType.integer, _line, value, int.parse(value));
  }

  Token _lexIdentifier() {
    String value = _previous();

    while (_isIdentifierAllowed(_peek())) {
      value += _advance();
    }

    TokenType? type = _keywords[value];

    return Token(type ?? TokenType.identifier, _line, value, value);
  }

  bool _isNumeric(String s) => s.codeUnitAt(0) >= 48 && s.codeUnitAt(0) <= 57;
  bool _isIdentifierAllowed(String s) => 
    _isNumeric(s) ||
    s.codeUnitAt(0) == 60 || s.codeUnitAt(0) == 62 || s.codeUnitAt(0) == 92 || s.codeUnitAt(0) == 94 || s.codeUnitAt(0) == 95 || s.codeUnitAt(0) == 124 || s.codeUnitAt(0) == 126 ||
    (s.codeUnitAt(0) >= 65 && s.codeUnitAt(0) <= 90) ||
    (s.codeUnitAt(0) >= 97 && s.codeUnitAt(0) <= 122);

  bool _atEnd() {
    return _current >= _content.length;
  }

  String _previous() {
    return String.fromCharCode(_content.codeUnitAt(_current - 1));
  }

  String _peek() {
    return String.fromCharCode(_content.codeUnitAt(_current));
  }

  String _advance() {
    if (_atEnd()) throw LexingException(1, _line, _previous(), "File ended early.");
    return String.fromCharCode(_content.codeUnitAt(_current++));
  }
}