import 'package:nocturne_design/interpret/symbol.dart';

class Environment {
  final Environment? _parent;
  final Map<String, NSymbol> _symbols;

  Environment(this._parent): _symbols = {};

  void define(String key, NSymbol symbol) => _symbols[key] = symbol;

  Environment exit() => _parent!;
}