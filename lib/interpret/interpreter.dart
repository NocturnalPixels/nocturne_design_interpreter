import 'package:nocturne_design/interpret/environment.dart';
import 'package:nocturne_design/interpret/interpret_exception.dart';
import 'package:nocturne_design/interpret/native_methods.dart';
import 'package:nocturne_design/interpret/resolving/resolver.dart';
import 'package:nocturne_design/interpret/symbols/symbol.dart';
import 'package:nocturne_design/interpret/symbols/symbol_collector.dart';
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

class Interpreter {
  final List<Statement> _statements;
  late Environment _current;

  Interpreter(this._statements);

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
        _interpretStatement(s.body);
        return true;
      }
    }

    return false;
  }

  void _interpretStatement(Statement s) {
    switch (s) {
      case BlockStatement block:
        for (Statement element in block.body) {_interpretStatement(element);}
        break;
      case CallStatement call:
        _call(call);
        break;

      case ReturnStatement ret:
        if (ret.value == null) {
          throw ReturnException(null);
        }
        else {
          throw ReturnException(_expression(ret.value!));
        }

      case FunctionStatement _:
        break;

      default:
        throw InterpretError("Non-implemented statement ${s.runtimeType}.");
    }
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

  dynamic _expression(Expression e) {
    switch (e) {
      case CallExpression call:
        return _callExpression(call);
      case LiteralExpression literal:
        return literal.value;
      case VarExpression varL:
        return _current.get(_current.find(varL.identifier));
      default:
        throw InterpretError("Non-implemented expression ${e.runtimeType}.");
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
}