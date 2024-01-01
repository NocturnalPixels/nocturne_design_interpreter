import "dart:io";

import 'package:nocturne_design/console_util.dart';
import 'package:nocturne_design/debug/ast_printer.dart';
import 'package:nocturne_design/interpret/interpreter.dart';
import 'package:nocturne_design/lex/lexer.dart';
import 'package:nocturne_design/lex/token.dart';
import 'package:nocturne_design/parse/parser.dart';
import 'package:nocturne_design/parse/statement.dart';

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
  List<Token> tokens = lexer.lex();

  Parser parser = Parser(tokens);

  List<Statement> stmts = parser.parse();
  for (Statement element in stmts) { AstPrinter(element).print(); }
  
  Interpreter interpreter = Interpreter(stmts);
  interpreter.interpret();
}
