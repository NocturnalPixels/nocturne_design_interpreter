import 'package:nocturne_design/lex/token.dart';

abstract class NSymbol {
  const NSymbol();
}

class FunctionSymbol extends NSymbol {
  final Token? type;

  const FunctionSymbol(this.type);
}

class VariableSymbol extends NSymbol {
  final Token? type;
  final int properties;

  const VariableSymbol(this.type, this.properties);
}