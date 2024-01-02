import 'dart:io';

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

  NativeFunctionSymbol(this.name, this.returnType, this.params, this.impl): super(Token(TokenType.identifier, -1, name, name));
}

class NativeVariableSymbol extends NSymbol {
  final String name;
  final NType type;
  
  NativeVariableSymbol(this.name, this.type): super(Token(TokenType.identifier, -1, name, name));
}

Map<String, NativeFunctionSymbol> _nativeMethods = {
  "print": NativeFunctionSymbol("print", getTypeF("void"), [
    NativeVariableSymbol("text", getTypeF("dynamic"))
  ], _nPrint),
  "input": NativeFunctionSymbol("input", getTypeF("string"), [], _readLn),
  "==": NativeFunctionSymbol("==", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("dynamic")),
    NativeVariableSymbol("b", getTypeF("dynamic")),
  ], _equals),
  "!=": NativeFunctionSymbol("!=", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("dynamic")),
    NativeVariableSymbol("b", getTypeF("dynamic")),
  ], nequals),
  "<": NativeFunctionSymbol("<", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], _less),
  "<=": NativeFunctionSymbol("<=", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], _lessEquals),
  ">": NativeFunctionSymbol(">", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], _greater),
  ">=": NativeFunctionSymbol(">=", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], _greaterEquals),
  "&&": NativeFunctionSymbol("&&", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("bool")),
    NativeVariableSymbol("b", getTypeF("bool")),
  ], _and),
  "||": NativeFunctionSymbol("||", getTypeF("bool"), [
    NativeVariableSymbol("a", getTypeF("bool")),
    NativeVariableSymbol("b", getTypeF("bool")),
  ], _or),
  "+": NativeFunctionSymbol("+", getTypeF("dynamic"), [
    NativeVariableSymbol("a", getTypeF("dynamic")),
    NativeVariableSymbol("b", getTypeF("dynamic")),
  ], _plus),
  "-": NativeFunctionSymbol("-", getTypeF("real"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], _minus),
  "*": NativeFunctionSymbol("*", getTypeF("real"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], _multiply),
  "/": NativeFunctionSymbol("/", getTypeF("real"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], _divide),
  "%": NativeFunctionSymbol("%", getTypeF("real"), [
    NativeVariableSymbol("a", getTypeF("real")),
    NativeVariableSymbol("b", getTypeF("real")),
  ], _modulo),
};

bool existsNativeMethod(String name) => _nativeMethods.containsKey(name);

NativeFunctionSymbol getNativeMethod(String name) => _nativeMethods[name]!;
Map<String, NativeFunctionSymbol> getNativeMethods() => _nativeMethods;

dynamic _nPrint(List<dynamic> args) {
  print(args[0]);
}

dynamic _equals(List<dynamic> args) {
  return args[0] == args[1];
}

dynamic nequals(List<dynamic> args) {
  return !_equals(args);
}

dynamic _less(List<dynamic> args) {
  return args[0] < args[1];
}

dynamic _lessEquals(List<dynamic> args) {
  return args[0] <= args[1];
}

dynamic _greater(List<dynamic> args) {
  return args[0] > args[1];
}

dynamic _greaterEquals(List<dynamic> args) {
  return args[0] >= args[1];
}

dynamic _and(List<dynamic> args) {
  return args[0] && args[1];
}

dynamic _or(List<dynamic> args) {
  return args[0] || args[1];
}

dynamic _plus(List<dynamic> args) {
  return add(args[0], args[1]);
}

dynamic _minus(List<dynamic> args) {
  return args[0] - args[1];
}

dynamic _multiply(List<dynamic> args) {
  return args[0] * args[1];
}

dynamic _divide(List<dynamic> args) {
  return args[0] / args[1];
}

dynamic _modulo(List<dynamic> args) {
  return args[0] % args[1];
}

dynamic _readLn(List<dynamic> args) {
  return stdin.readLineSync() ?? "";
}