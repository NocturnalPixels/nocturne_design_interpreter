import 'package:nocturne_design/interpret/symbols/symbol.dart';
import 'package:nocturne_design/interpret/typing/type.dart';
import 'package:nocturne_design/interpret/typing/type_checker.dart';
import 'package:nocturne_design/lex/token.dart';

class NativeFunctionSymbol extends NSymbol {
  final String name;
  final NType returnType;
  final List<NativeVariableSymbol> params;
  final Function impl;

  NativeFunctionSymbol(this.name, this.returnType, this.params, this.impl): super(Token(TokenType.identifier, -1, name, null));
}

class NativeVariableSymbol extends NSymbol {
  final String name;
  final NType type;
  
  NativeVariableSymbol(this.name, this.type): super(Token(TokenType.identifier, -1, name, null));
}

Map<String, NativeFunctionSymbol> _nativeMethods = {
  "print": NativeFunctionSymbol("print", getTypeF("void"), [
    NativeVariableSymbol("text", getTypeF("dynamic"))
  ], _nPrint)
};

bool existsNativeMethod(String name) => _nativeMethods.containsKey(name);

NativeFunctionSymbol getNativeMethod(String name) => _nativeMethods[name]!;

void _nPrint(List<dynamic> args) {
  print(args[0]);
}