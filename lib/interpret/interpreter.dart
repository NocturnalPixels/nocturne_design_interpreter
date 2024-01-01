import 'package:nocturne_design/interpret/environment.dart';
import 'package:nocturne_design/interpret/interpret_exception.dart';
import 'package:nocturne_design/interpret/native_methods.dart';
import 'package:nocturne_design/interpret/resolving/resolver.dart';
import 'package:nocturne_design/interpret/symbols/symbol.dart';
import 'package:nocturne_design/interpret/symbols/symbol_collector.dart';
import 'package:nocturne_design/interpret/typing/type_converter.dart';
import 'package:nocturne_design/lex/token.dart';
import 'package:nocturne_design/parse/expression.dart';
import 'package:nocturne_design/parse/statement.dart';

class InterpretError extends Error {
  final String _message;

  InterpretError(this._message);

  @override
  String toString() {
    return _message;
  }
}

class ReturnException implements Exception {
  final dynamic value;

  const ReturnException(this.value);
}

class BreakException implements Exception {

}

class Interpreter {
  final List<Statement> _statements;
  late Environment _current;

  int _unnamedEnvCount;

  Interpreter(this._statements): _unnamedEnvCount = 0;

  void interpret() {
    SymbolCollector collector = SymbolCollector(_statements);
    _current = collector.collect();
    Resolver resolver = Resolver(_statements, _current);
    resolver.resolve();
    if (!_callMain()) {
      throw InterpretException(InterpretExceptionType.noEntryPointFound, Token(TokenType.eof, -1, "<EoF>", null), "No entry point found.");
    }
  }

  bool _callMain() {
    for (Statement s in _statements) {
      if (s is! FunctionStatement) continue;
      if (s.name.lexeme == "main" && s.parameters.length == 1 && s.parameters[0].name.lexeme == "args") {
        FunctionSymbol f = _current.find(s.name) as FunctionSymbol;
        _current = f.env;
        _interpretStatement(s.body);
        _current = _current.exit();
        return true;
      }
    }

    return false;
  }

  void _interpretStatement(Statement s) {
    switch (s) {
      case AssignStatement assign:
        _assign(assign);
        break;
      case BlockStatement block:
        BlockSymbol s = _current.findF((_unnamedEnvCount++).toString()) as BlockSymbol;
        _current = s.env;
        for (Statement element in block.body) {_interpretStatement(element);}
        _current = _current.exit();
        break;
      case BreakStatement _:
        throw BreakException();
      case CallStatement call:
        _call(call);
        break;
      case DeclarationStatement decl:
        _decl(decl);
        break;
      case ForStatement forL:
        _for(forL);
        break;
      case FunctionStatement _:
        break;
      case IfStatement ifL:
        _if(ifL);
        break;
      case ReturnStatement ret:
        if (ret.value == null) {
          throw ReturnException(null);
        }
        else {
          throw ReturnException(_expression(ret.value!));
        }
      case WhileStatement whileL:
        _while(whileL);
        break;

      default:
        throw InterpretError("Non-implemented statement ${s.runtimeType}.");
    }
  }

  void _assign(AssignStatement a) {
    _current.define(_current.find(a.left), _expression(a.right));
  }

  void _call(CallStatement c) {
    NSymbol s = _current.find(c.identifier);
    if (s is FunctionSymbol) {
      _current = s.env;
      for (int i = 0; i < s.params.length; i++) {
        _current.define(s.params[i], _expression(c.arguments[i]));
      }

      try {
        _interpretStatement(s.body);
      } on ReturnException {
        return;
      }

      _current = _current.exit();
    }
    else if (s is NativeFunctionSymbol) {
      List<dynamic> params = [];
      for (Expression arg in c.arguments) {
        params.add(_expression(arg));
      }
      s.impl.call(params);
    }
  }

  void _decl(DeclarationStatement d) {
    if (d.initializer != null) {
      _current.define(_current.find(d.name), _expression(d.initializer!));
    }
  }

  void _for(ForStatement f) {
    EnvironmentSymbol e = _current.findF((_unnamedEnvCount++).toString()) as EnvironmentSymbol;
    _current = e.env;
    _decl(f.initializer);
    _unnamedEnvCount++;
    while (!_expression(f.condition)) {
      _unnamedEnvCount--;
      _interpretStatement(f.body);
      _assign(f.increment);
    }
    _current = _current.exit();
  }

  void _if(IfStatement i) {
    EnvironmentSymbol ifBranch = _current.findF((_unnamedEnvCount++).toString()) as EnvironmentSymbol;
    int elseIndex = _unnamedEnvCount++;
    EnvironmentSymbol? elseBranch;
    if (i.elseBranch != null) {
      elseBranch = _current.findF(elseIndex.toString()) as EnvironmentSymbol;
    }

    if (_expression(i.condition) == true) {
      _current = ifBranch.env;
      _interpretStatement(ifBranch.body);
      _current = _current.exit();
    }
    else if (elseBranch != null) {
      _current = elseBranch.env;
      _interpretStatement(elseBranch.body);
      _current = _current.exit();
    }
  }

  void _while(WhileStatement w) {
    EnvironmentSymbol e = _current.findF((_unnamedEnvCount++).toString()) as EnvironmentSymbol;
    _current = e.env;
    _unnamedEnvCount++;
    while (_expression(w.condition)) {
      _unnamedEnvCount--;
      _interpretStatement(w.body);
    }
    _current = _current.exit();
  }

  dynamic _expression(Expression e) {
    switch (e) {
      case AssignExpression assign:
        return _assignExpression(assign);
      case BinaryExpression binary:
        return _binary(binary);
      case CallExpression call:
        return _callExpression(call);
      case GroupingExpression group:
        return _expression(group.expression);
      case LiteralExpression literal:
        return literal.value;
      case UnaryExpression unary:
        return _unary(unary);
      case VarExpression varL:
        return _current.get(_current.find(varL.identifier));
      default:
        throw InterpretError("Non-implemented expression ${e.runtimeType}.");
    }
  }

  dynamic _assignExpression(AssignExpression a) {
    _current.define(_current.find(a.left), _expression(a.right));
    return _current.get(_current.find(a.left));
  }

  dynamic _binary(BinaryExpression b) {
    NSymbol s = _current.find(b.op);

    if (s is FunctionSymbol) {
      _current = s.env;
      _current.define(s.params[0], _expression(b.left));
      _current.define(s.params[1], _expression(b.right));

      dynamic value;

      try {
        _interpretStatement(s.body);
      } on ReturnException catch (ex) {
        value = ex.value;
      }

      _current = _current.exit();

      return value;
    }
    else if (s is NativeFunctionSymbol) {
      List<dynamic> params = [];
      params.add(_expression(b.left));
      params.add(_expression(b.right));
      return s.impl.call(params);
    }
  }

  dynamic _callExpression(CallExpression c) {
    NSymbol s = _current.find(c.identifier);
    if (s is FunctionSymbol) {
      _current = s.env;
      for (int i = 0; i < s.params.length; i++) {
        _current.define(s.params[i], _expression(c.arguments[i]));
      }

      try {
        _interpretStatement(s.body);
      } on ReturnException catch (ex) {
        return ex.value;
      }

      _current = _current.exit();
    }
    else if (s is NativeFunctionSymbol) {
      List<dynamic> params = [];
      for (Expression arg in c.arguments) {
        params.add(_expression(arg));
      }
      return s.impl.call(params);
    }
  }

  dynamic _unary(UnaryExpression u) {
    switch (u.op.tokenType) {
      case TokenType.bang:
        return not(_expression(u.right));
      case TokenType.minus:
        return negate(_expression(u.right));
      default:
        throw InterpretError("Unimplemented unary operator.");
    }
  }
}