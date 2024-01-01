import 'package:nocturne_design/interpret/interpreter.dart';

dynamic not(dynamic v) {
  if (v is bool) {
    return !v;
  }

  throw InterpretError("Uncaught type mismatch in interpreting.");
}

dynamic negate(dynamic v) {
  if (v is int || v is double) {
    return -v;
  }

  throw InterpretError("Uncaught type mismatch in interpreting.");
}