import 'package:nocturne_design/interpret/natives/native_methods.dart';
import 'package:nocturne_design/interpret/symbols/symbol.dart';
import 'package:nocturne_design/interpret/typing/type.dart';
import 'package:nocturne_design/interpret/typing/type_checker.dart';
import 'package:nocturne_design/lex/token.dart';

class NativeTypeSymbol extends NSymbol {
  final String name;
  final List<NativeFunctionSymbol> methods;

  NativeTypeSymbol(this.name, this.methods) : super(Token(TokenType.identifier, -1, name, name));
}

Map<NType, NativeTypeSymbol> _types = {
  getTypeF("int"): NativeTypeSymbol("int", [
    NativeFunctionSymbol("parse", getTypeF("int"), [
      NativeVariableSymbol("value", getTypeF("string"))
    ], _parseInt)
  ]),
  getTypeF("string"): NativeTypeSymbol("string", [
    NativeFunctionSymbol("lower", getTypeF("string"), [
      NativeVariableSymbol("value", getTypeF("string"))
    ], _lower)
  ])
};

Map<NType, NativeTypeSymbol> getNativeTypes() => _types;

bool existsNativeType(NType type) => _types.containsKey(type);

NativeTypeSymbol getNativeType(NType type) => _types[type]!;

dynamic _parseInt(List<dynamic> args) {
  return int.parse(args[0]);
}

dynamic _lower(List<dynamic> args) {
  return (args[0] as String).toLowerCase();
}