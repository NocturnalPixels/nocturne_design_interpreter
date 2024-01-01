import 'package:nocturne_design/interpret/symbols/symbol.dart';
import 'package:nocturne_design/interpret/typing/type.dart';
import 'package:nocturne_design/interpret/typing/type_checker.dart';
import 'package:nocturne_design/interpret/typing/type_converter.dart';
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
  ], _nPrint),
  "==": NativeFunctionSymbol("==", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("dynamic")),
    NativeVariableSymbol("b", getTypeF("dynamic")),
  ], equals),
  "!=": NativeFunctionSymbol("!=", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("dynamic")),
    NativeVariableSymbol("b", getTypeF("dynamic")),
  ], nequals),
  "<": NativeFunctionSymbol("<", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], less),
  "<=": NativeFunctionSymbol("<=", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], lessEquals),
  ">": NativeFunctionSymbol(">", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], greater),
  ">=": NativeFunctionSymbol(">=", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], greaterEquals),
  "&&": NativeFunctionSymbol("&&", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("bool")),
    NativeVariableSymbol("b", getTypeF("bool")),
  ], and),
  "||": NativeFunctionSymbol("||", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("bool")),
    NativeVariableSymbol("b", getTypeF("bool")),
  ], or),
  "+": NativeFunctionSymbol("||", getTypeF("dynamic"), [
    NativeVariableSymbol("a", getTypeF("dynamic")),
    NativeVariableSymbol("b", getTypeF("dynamic")),
  ], plus),
  "-": NativeFunctionSymbol("||", getTypeF("real"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], minus),
  "*": NativeFunctionSymbol("||", getTypeF("real"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], multiply),
  "/": NativeFunctionSymbol("||", getTypeF("real"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], divide),
  "%": NativeFunctionSymbol("%", getTypeF("real"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], modulo)
};

bool existsNativeMethod(String name) => _nativeMethods.containsKey(name);

NativeFunctionSymbol getNativeMethod(String name) => _nativeMethods[name]!;

dynamic _nPrint(List<dynamic> args) {
  print(args[0]);
}

dynamic equals(List<dynamic> args) {
  return args[0] == args[1];
}

dynamic nequals(List<dynamic> args) {
  return !equals(args);
}

dynamic less(List<dynamic> args) {
  return args[0] < args[1];
}

dynamic lessEquals(List<dynamic> args) {
  return args[0] <= args[1];
}

dynamic greater(List<dynamic> args) {
  return args[0] > args[1];
}

dynamic greaterEquals(List<dynamic> args) {
  return args[0] >= args[1];
}

dynamic and(List<dynamic> args) {
  return args[0] && args[1];
}

dynamic or(List<dynamic> args) {
  return args[0] || args[1];
}

dynamic plus(List<dynamic> args) {
  return add(args[0], args[1]);
}

dynamic minus(List<dynamic> args) {
  return args[0] - args[1];
}

dynamic multiply(List<dynamic> args) {
  return args[0] * args[1];
}

dynamic divide(List<dynamic> args) {
  return args[0] / args[1];
}

dynamic modulo(List<dynamic> args) {
  return args[0] % args[1];
}