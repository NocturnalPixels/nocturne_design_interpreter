import 'package:nocturne_design/console_util.dart';

enum LexingExceptionType {
  earlyEof
}

class LexingException implements Exception {
  final LexingExceptionType exceptionCode;
  final int line;
  final String offender;
  final String message;

  const LexingException(this.exceptionCode, this.line, this.offender, this.message);

  @override
  String toString() => colorRed("L${exceptionCode.index}: \"$message\" at '$offender' on line $line.");
}