import 'package:nocturne_design/console_util.dart';
import 'package:nocturne_design/lex/token.dart';

class ParsingException implements Exception {
  final int exceptionCode;
  final Token offender;
  final String message;

  const ParsingException(this.exceptionCode, this.offender, this.message);

  @override
  String toString() => colorRed("P$exceptionCode: \"$message\" at '${offender.lexeme}' on line ${offender.line}.");
}