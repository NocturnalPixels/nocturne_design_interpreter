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

  int _unnamedEnvCount;

  SymbolCollector(this._statements): _current = Environment(null), _unnamedEnvCount = 0;

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
        Environment env = _current = Environment(_current);
        int index = _unnamedEnvCount++;
        for (Statement element in block.body) { _statement(element); }
        _current = _current.exit();
        _current.declare(index.toString(), BlockSymbol(block.blame, index, env, block.body));
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
        _if(ifL);
        break;

      case WhileStatement whileL:
        _while(whileL);
        break;

      default:
        throw SymbolCollectionError("Missing Statement implementation in symbol collection.");
    }
  }

  void _declaration(DeclarationStatement d) {
    _current.declare(d.name.tokenValue, VariableSymbol(d.name, d.type, d.properties));
  }

  void _for(ForStatement f) {
    Environment env = _current = Environment(_current);
    int index = _unnamedEnvCount++;
    _declaration(f.initializer);
    _statement(f.body);
    _current = _current.exit();
    _current.declare(index.toString(), EnvironmentSymbol(f.blame, index, env, f.body));
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

  void _if(IfStatement i) {
    Environment env = _current = Environment(_current);
    int index = _unnamedEnvCount++;
    int elseIndex = _unnamedEnvCount++;
    _statement(i.ifBranch);
    if (i.elseBranch != null) _statement(i.elseBranch!);
    _current = _current.exit();
    _current.declare(index.toString(), EnvironmentSymbol(i.blame, index, env, i.ifBranch));
    if (i.elseBranch != null) {
      _current.declare(elseIndex.toString(), EnvironmentSymbol(i.blame, elseIndex, env, i.elseBranch!));
    }
  }

  void _while(WhileStatement w) {
    Environment env = _current = Environment(_current);
    int index = _unnamedEnvCount++;
    _statement(w.body);
    _current = _current.exit();
    _current.declare(index.toString(), EnvironmentSymbol(w.blame, index, env, w.body));
  }
}