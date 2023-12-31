import 'package:nocturne_design/interpret/environment.dart';
import 'package:nocturne_design/interpret/symbols/symbol.dart';
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

      case IfStatement ifL:
        _current = Environment(_current);
        _statement(ifL.ifBranch);
        if (ifL.elseBranch != null) _statement(ifL.elseBranch!);
        _current = _current.exit();
        break;

      case WhileStatement whileL:
        _current = Environment(_current);
        _statement(whileL.body);
        _current = _current.exit();
        break;

      default:
        throw SymbolCollectionError("Missing Statement implementation in symbol collection.");
    }
  }

  void _declaration(DeclarationStatement d) {
    _current.declare(d.name.tokenValue, VariableSymbol(d.name, d.type, d.properties));
  }

  void _for(ForStatement f) {
    _current = Environment(_current);
    _declaration(f.initializer);
    _statement(f.body);
    _current = _current.exit();
  }

  void _function(FunctionStatement f) {
    Environment fn = _current = Environment(_current);

    List<VariableSymbol> params = [];
    for (DeclarationStatement param in f.parameters) {
      VariableSymbol v = VariableSymbol(param.name, param.type, param.properties);
      params.add(v);
      _current.declare(param.name.tokenValue, v);
    }

    _statement(f.body);

    _current = _current.exit();
    _current.declare(f.name.tokenValue, FunctionSymbol(f.name, f.returnType, params, fn, f.body));
  }
}