import 'package:nocturne_design/console_util.dart';

class LexingException implements Exception {
  int exceptionCode;
  int line;
  String offender;
  String message;

  LexingException(this.exceptionCode, this.line, this.offender, this.message);

  @override
  String toString() => colorRed("L$exceptionCode: \"$message\" at '$offender' on line $line.");
}