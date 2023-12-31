import "dart:io";

import 'package:nocturne_design/console_util.dart';
import 'package:nocturne_design/lex/lexer.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print(colorRed("Not enough console arguments."));
    return;
  }

  File file = File(arguments[0]);

  if (!file.existsSync()) {
    print(colorRed("Could not read file ${arguments[0]}"));
    return;
  }

  Lexer lexer = Lexer(file.readAsStringSync());
  print(lexer.lex());
}
