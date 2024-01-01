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
        Environment env = _current = Environment(_current);
        for (Statement element in block.body) { _statement(element); }
        _current = _current.exit();
        _current.declare(block.uid.toString(), BlockSymbol(block.blame, block.uid, env, block.body));
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

      case ModStatement mod:
        _mod(mod);
        break;

      case StructStatement str:
        _struct(str);
        break;

      case IfStatement ifL:
        _if(ifL);
        break;

      case WhileStatement whileL:
        _while(whileL);
        break;

      case AccessorStatement _:
        break;

      default:
        throw SymbolCollectionError("Missing Statement implementation in symbol collection.");
    }
  }

  VariableSymbol _declaration(DeclarationStatement d) {
    VariableSymbol v = VariableSymbol(d.name, d.type, d.properties);
    _current.declare(d.name.tokenValue, v);
    return v;
  }

  void _for(ForStatement f) {
    Environment env = _current = Environment(_current);
    _declaration(f.initializer);
    _statement(f.body);
    _current = _current.exit();
    _current.declare(f.uid.toString(), EnvironmentSymbol(f.blame, f.uid, env, f.body));
  }

  FunctionSymbol _function(FunctionStatement f) {
    Environment fn = _current = Environment(_current);

    List<VariableSymbol> params = [];
    for (DeclarationStatement param in f.parameters) {
      VariableSymbol v = VariableSymbol(param.name, param.type, param.properties);
      params.add(v);
      _current.declare(param.name.tokenValue, v);
    }

    _statement(f.body);

    _current = _current.exit();
    FunctionSymbol sym = FunctionSymbol(f.name, f.returnType, params, fn, f.body);
    _current.declare(f.name.tokenValue, sym);
    return sym;
  }

  void _if(IfStatement i) {
    Environment env = _current = Environment(_current);
    _statement(i.ifBranch);
    if (i.elseBranch != null) _statement(i.elseBranch!);
    _current = _current.exit();
    _current.declare((i.uid - 1).toString(), EnvironmentSymbol(i.blame, i.uid - 1, env, i.ifBranch));
    if (i.elseBranch != null) {
      _current.declare(i.uid.toString(), EnvironmentSymbol(i.blame, i.uid, env, i.elseBranch!));
    }
  }

  void _mod(ModStatement m) {
    Environment env = _current = Environment(_current);

    List<FunctionSymbol> methods = [for (FunctionStatement f in m.methods) _function(f)];

    _current = _current.exit();
    _current.declare(m.name.tokenValue + "§impl", ModSymbol(m.name, m.name, methods, env));
  }

  void _struct(StructStatement s) {
    Environment env = _current = Environment(_current);

    List<VariableSymbol> properties = [for (DeclarationStatement d in s.properties) _declaration(d)];

    _current = _current.exit();
    _current.declare(s.name.tokenValue + "§decl", StructSymbol(s.name, s.name, properties, env));
    _current.declare(s.name.tokenValue, ConstructorSymbol(s.name, s.name, properties));
  }

  void _while(WhileStatement w) {
    Environment env = _current = Environment(_current);
    _statement(w.body);
    _current = _current.exit();
    _current.declare(w.uid.toString(), EnvironmentSymbol(w.blame, w.uid, env, w.body));
  }
}