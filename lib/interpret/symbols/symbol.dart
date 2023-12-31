import 'package:nocturne_design/interpret/environment.dart';
import 'package:nocturne_design/lex/token.dart';
import 'package:nocturne_design/parse/statement.dart';

abstract class NSymbol {
  final Token blame;

  NSymbol(this.blame);
}

class FunctionSymbol extends NSymbol {
  final Token? type;
  final List<VariableSymbol> params;
  final Environment env;
  final Statement body;

  FunctionSymbol(super.blame, this.type, this.params, this.env, this.body);
}

class VariableSymbol extends NSymbol {
  final Token? type;
  final int properties;

  VariableSymbol(super.blame, this.type, this.properties);
}

class LiteralSymbol extends NSymbol {
  final dynamic value;

  LiteralSymbol(super.blame, this.value);
}