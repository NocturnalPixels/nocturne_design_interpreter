import 'package:nocturne_design/console_util.dart';
import 'package:nocturne_design/lex/token.dart';

enum ParsingExceptionType {
  undefinedStatement,
  missingSemicolon,
  missingClosingParentheses,
  missingClosingBrace,
  missingClosingBracket,
  floatingIdentifier,
  missingType,
  missingOpeningParentheses,
  expectedIdentifier,
  uncaughtToken
}

class ParsingException implements Exception {
  final ParsingExceptionType exceptionCode;
  final Token offender;
  final String message;

  const ParsingException(this.exceptionCode, this.offender, this.message);

  @override
  String toString() => colorRed("P${exceptionCode.index}: \"$message\" at '${offender.lexeme}' on line ${offender.line}.");
}