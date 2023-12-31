import 'package:nocturne_design/interpret/environment.dart';
import 'package:nocturne_design/interpret/symbol.dart';
import 'package:nocturne_design/parse/statement.dart';

class SymbolCollectionError extends Error {
  final String _message;

  SymbolCollectionError(this._message);

  @override
  String toString() {
    return _message;
  }
}

class SymbolCollector {
  final List<Statement> _statements;
  Environment _current;

  SymbolCollector(this._statements): _current = Environment(null);

  Environment collect() {
    for (Statement s in _statements) {
      _statement(s);
    }

    return _current;
  }

  void _statement(Statement s) {
    switch (s) {
      case AssignStatement _:
      case BreakStatement _:
      case CallStatement _:
      case ReturnStatement _:
        break;

      case BlockStatement block:
        _current = Environment(_current);
        for (Statement element in block.body) { _statement(element); }
        _current = _current.exit();
        break;

      case DeclarationStatement decl:
        _declaration(decl);
        break;

      case ForStatement forL:
        _for(forL);
        break;

      case FunctionStatement func:
        _function(func);
        break;
      default:
        throw SymbolCollectionError("Missing Statement implementation in symbol collection.");
    }
  }

  void _declaration(DeclarationStatement d) {
    _current.define(d.name.tokenValue, VariableSymbol(d.type, d.properties));
  }

  void _for(ForStatement f) {
    _current = Environment(_current);
    _declaration(f.initializer);

    _statement(f.body);

    _current = _current.exit();
  }

  void _function(FunctionStatement f) {
    _current.define(f.name.tokenValue, FunctionSymbol(f.returnType));
    _current = Environment(_current);

    for (DeclarationStatement param in f.parameters) {
      _current.define(param.name.tokenValue, VariableSymbol(param.type, param.properties));
    }

    _statement(f.body);

    _current = _current.exit();
  }
}