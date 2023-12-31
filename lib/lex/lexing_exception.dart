import 'package:nocturne_design/console_util.dart';

class LexingException implements Exception {
  final int exceptionCode;
  final int line;
  final String offender;
  final String message;

  const LexingException(this.exceptionCode, this.line, this.offender, this.message);

  @override
  String toString() => colorRed("L$exceptionCode: \"$message\" at '$offender' on line $line.");
}