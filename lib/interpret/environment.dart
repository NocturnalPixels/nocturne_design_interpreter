import 'package:nocturne_design/interpret/interpret_exception.dart';
import 'package:nocturne_design/interpret/native_methods.dart';
import 'package:nocturne_design/interpret/resolving/resolver.dart';
import 'package:nocturne_design/interpret/symbols/symbol.dart';
import 'package:nocturne_design/lex/token.dart';

import 'resolving/resolving_exception.dart';

class Environment {
  final Environment? _parent;
  final Map<String, NSymbol> _symbols;
  final Map<NSymbol, dynamic> _valueTable;
  final List<Environment> _children;

  Environment(this._parent): _symbols = {}, _valueTable = {}, _children = [] {
    _parent?.addChild(this);
  }

  void addChild(Environment e) {
    _children.add(e);
  }

  void declare(String key, NSymbol symbol) {
    if (_symbols.containsKey(key)) {
      throw ResolvingException(ResolvingExceptionType.alreadyDefinedSymbol, symbol.blame, "Symbol already defined.");
    }
    _symbols[key] = symbol;
  }
  void define(NSymbol symbol, dynamic value) {
    if (_symbols.containsValue(symbol)) {
      _valueTable[symbol] = value;
    }
    else if (_parent != null) {
      _parent.define(symbol, value);
    }
  }

  NSymbol find(Token key) {
    if (existsNativeMethod(key.tokenValue)) {
      return getNativeMethod(key.tokenValue);
    }

    if (_symbols.containsKey(key.tokenValue)) {
      return _symbols[key.tokenValue]!;
    }

    if (_parent != null) {
      return _parent.find(key);
    }

    throw ResolvingException(ResolvingExceptionType.undefinedSymbol, key, "Undefined Symbol");
  }

  NSymbol findF(String key) {
    if (_symbols.containsKey(key)) {
      return _symbols[key]!;
    }

    if (_parent != null) {
      return _parent.findF(key);
    }

    throw ResolvingError("Non-existent anonymous.");
  }

  dynamic get(NSymbol key) {
    if (_valueTable.containsKey(key)) {
      return _valueTable[key];
    }

    if (_parent != null) {
      return _parent.get(key);
    }

    throw InterpretException(InterpretExceptionType.undefinedSymbol, key.blame, "Undefined Symbol");
  }

  Environment exit() => _parent!;
}