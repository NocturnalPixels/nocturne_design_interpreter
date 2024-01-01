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

dynamic add(dynamic a, dynamic b) {
  if ((a is int || a is double) && (b is int || b is double)) {
    return a + b;
  }

  if (a is String || b is String) {
    return a.toString() + b.toString();
  }
}