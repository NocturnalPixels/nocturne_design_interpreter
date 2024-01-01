import 'package:nocturne_design/interpret/environment.dart';
import 'package:nocturne_design/interpret/symbols/symbol.dart';
import 'package:nocturne_design/interpret/typing/type.dart';
import 'package:nocturne_design/lex/token.dart';

class NInstance {
  final Token? identifier;
  final NType type;
  final Map<VariableSymbol, dynamic> properties;
  final Environment env;

  NInstance(this.identifier, this.type, this.properties, this.env) {
    for (MapEntry<VariableSymbol, dynamic> prop in properties.entries) {
      env.declare(prop.key.blame.tokenValue, prop.key);
      env.define(prop.key, prop.value);
    }
  }

  @override
  String toString() {
    return "Instance of '${identifier?.tokenValue ?? "dynamic"}'";
  }
}