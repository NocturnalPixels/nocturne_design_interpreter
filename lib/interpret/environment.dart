import 'package:nocturne_design/interpret/interpret_exception.dart';
import 'package:nocturne_design/interpret/native_methods.dart';
import 'package:nocturne_design/interpret/symbols/symbol.dart';
import 'package:nocturne_design/lex/token.dart';

import 'resolving/resolving_exception.dart';

class Environment {
  final Environment? _parent;
  final Map<String, NSymbol> _symbols;
  final Map<NSymbol, dynamic> _valueTable;

  Environment(this._parent): _symbols = {}, _valueTable = {};

  void declare(String key, NSymbol symbol) => _symbols[key] = symbol;
  void define(NSymbol symbol, dynamic value) => _valueTable[symbol] = value;

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