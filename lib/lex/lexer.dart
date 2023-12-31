import 'lexing_exception.dart';
import 'token.dart';

class Lexer {
  static const Map<String, TokenType> _keywords = {
    "fn": TokenType.function,
    "let": TokenType.let,
    "const": TokenType.constL,
    "true": TokenType.trueL,
    "false": TokenType.falseL,
    "null": TokenType.nullL
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

        default:
          if (_previous() == "/") {
            if (_peek() == "/") {
              while (_peek() != "\n" && !_atEnd()) {
                _advance();
              }
              break;
            }
            else if (_previous() == "*") {
              _advance();
              while (_advance() != "*" && _peek() != "/") {
                if (_peek() == '\n') {
                  _line++;
                }
              }

              _advance();
              break;
            }
          }

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

    while (_peek() != " " && _peek() != "\r" && _peek() != "\t") {
      value += _advance();
    }

    TokenType? type = _keywords[value];

    return Token(type ?? TokenType.identifier, _line, value, value);
  }

  bool _isNumeric(String s) => s.codeUnitAt(0) >= 48 && s.codeUnitAt(0) <= 57;

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