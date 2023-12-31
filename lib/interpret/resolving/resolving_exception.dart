import 'package:nocturne_design/console_util.dart';
import 'package:nocturne_design/lex/token.dart';

enum ResolvingExceptionType {
  undefinedSymbol,
  assigningToConstant,
  invalidType,
  noAssociatedType,
  typeMismatch,
  callTargetIsNotCallable,
  invalidArgumentCount,
  returningOutsideMethod,
  returningInvalidVoid, 
  alreadyDefinedSymbol,
  typeOverlap, 
  misplacedConstructor,
  leftSideOfAccessorWrong
}

class ResolvingException implements Exception {
  final ResolvingExceptionType _code;
  final String _message;
  final Token _offender;

  const ResolvingException(this._code, this._offender, this._message);

  @override
  String toString() => colorRed("R${_code.index}: \"$_message\" at '${_offender.lexeme}' on ${_offender.line}.");
}
