import 'package:nocturne_design/console_util.dart';
import 'package:nocturne_design/lex/token.dart';

enum InterpretExceptionType {
  noEntryPointFound,
  undefinedSymbol
}

class InterpretException implements Exception {
  final InterpretExceptionType _code;
  final String _message;
  final Token _offender;

  const InterpretException(this._code, this._offender, this._message);

  @override
  String toString() => colorRed("R${_code.index}: \"$_message\" at '${_offender.lexeme}' on ${_offender.line}.");
}
