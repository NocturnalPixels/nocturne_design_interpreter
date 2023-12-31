import 'package:enum_flag/enum_flag.dart';
import 'package:nocturne_design/interpret/environment.dart';
import 'package:nocturne_design/interpret/native_methods.dart';
import 'package:nocturne_design/interpret/resolving/resolving_exception.dart';
import 'package:nocturne_design/interpret/symbols/symbol.dart';
import 'package:nocturne_design/interpret/typing/type_checker.dart';
import 'package:nocturne_design/parse/expression.dart';
import 'package:nocturne_design/parse/statement.dart';

class ResolvingError extends Error {
  final String _message;

  ResolvingError(this._message);

  @override
  String toString() {
    return _message;
  }
}

class Resolver {
  final List<Statement> _statements;
  Environment _current;

  FunctionSymbol? _currentFunc;

  Resolver(this._statements, this._current): _currentFunc = null;

  void resolve() {
    for (Statement element in _statements) { _statement(element); }
  }

  void _statement(Statement s) {
    switch (s) {
      case AssignStatement assign:
        _assign(assign);
        break;
      case BlockStatement block:
        for (Statement element in block.body) { _statement(element); }
        break;
      case CallStatement call:
        _call(call);
        break;
      case FunctionStatement function:
        _function(function);
        break;
      case ReturnStatement ret:
        _return(ret);
        break;
      default:
        throw ResolvingError("Unimplemented statement in resolver ${s.runtimeType}");
    }
  }

  void _assign(AssignStatement a) {
    VariableSymbol vSym = _current.find(a.left) as VariableSymbol;
    if (vSym.properties.hasFlag(Properties.constant)) {
      throw ResolvingException(ResolvingExceptionType.assigningToConstant, a.left, "Can't assign to constant variable.");
    }

    if (!typesMatch(vSym, _expression(a.right))) {
      throw ResolvingException(ResolvingExceptionType.typeMismatch, a.left, "Type mismatch.");
    }
  }

  void _call(CallStatement c) {
    NSymbol s = _current.find(c.identifier);

    if (s is FunctionSymbol) {
      if (c.arguments.length != s.params.length) {
        throw ResolvingException(ResolvingExceptionType.invalidArgumentCount, c.identifier, "Function argument count does not match.");
      }

      for (int i = 0; i < c.arguments.length; i++) {
        if (!typesMatch(_expression(c.arguments[i]), s.params[i])) {
          throw ResolvingException(ResolvingExceptionType.invalidType, c.identifier, "Type does not match one specified in function signature.");
        }
      }
      return;
    }
    else if (s is NativeFunctionSymbol) {
      if (c.arguments.length != s.params.length) {
        throw ResolvingException(ResolvingExceptionType.invalidArgumentCount, c.identifier, "Function argument count does not match.");
      }

      for (int i = 0; i < c.arguments.length; i++) {
        if (!typesMatch(s.params[i], _expression(c.arguments[i]))) {
          throw ResolvingException(ResolvingExceptionType.invalidType, c.identifier, "Parameter type does not match one specified in function signature.");
        }
      }
      return;
    }

    throw ResolvingException(ResolvingExceptionType.callTargetIsNotCallable, c.identifier, "Call target is not function.");
  }

  void _function(FunctionStatement f) {
    _currentFunc = _current.find(f.name) as FunctionSymbol;
    _current = _currentFunc!.env;

    _statement(f.body);

    _currentFunc = null;
  }

  void _return(ReturnStatement r) {
    if (_currentFunc == null) {
      throw ResolvingException(ResolvingExceptionType.returningOutsideMethod, r.blame, "Can't return outside function.");
    }

    if (r.value == null) {
      if (evaluateType(_currentFunc!) != getType("void", _currentFunc!.blame)) {
        return;
      } else {
        throw ResolvingException(ResolvingExceptionType.returningInvalidVoid, r.blame, "Can't return nothing. Method is not of type void.");
      }
    }

    NSymbol value = _expression(r.value!);

    if (!typesMatch(_currentFunc!, value)) {
      throw ResolvingException(ResolvingExceptionType.invalidType, value.blame, "Return type does not match function type.");
    }
  }

  NSymbol _expression(Expression e) {
    switch (e) {
      case AssignExpression assign:
        return _assignExpression(assign);
      case CallExpression call:
        return _callExpression(call);
      case LiteralExpression literal:
        return LiteralSymbol(literal.blame, literal.value);
      case VarExpression varL:
        return _current.find(varL.identifier);
      default:
        throw ResolvingError("Missing implemented expression in resolver ${e.runtimeType}");
    }
  }

  NSymbol _assignExpression(AssignExpression a) {
    VariableSymbol vSym = _current.find(a.left) as VariableSymbol;
    if (vSym.properties.hasFlag(Properties.constant)) {
      throw ResolvingException(ResolvingExceptionType.assigningToConstant, a.left, "Can't assign to constant variable.");
    }

    NSymbol value = _expression(a.right);

    if (!typesMatch(vSym, value)) {
      throw ResolvingException(ResolvingExceptionType.typeMismatch, a.left, "Type mismatch.");
    }

    return value;
  }

  NSymbol _callExpression(CallExpression c) {
    NSymbol s = _current.find(c.identifier);

    if (s is! FunctionSymbol) {
      throw ResolvingException(ResolvingExceptionType.callTargetIsNotCallable, c.identifier, "Call target is not function.");
    }

    if (c.arguments.length != s.params.length) {
      throw ResolvingException(ResolvingExceptionType.invalidArgumentCount, c.identifier, "Function argument count does not match.");
    }

    for (int i = 0; i < c.arguments.length; i++) {
      if (!typesMatch(_expression(c.arguments[i]), s.params[i])) {
        throw ResolvingException(ResolvingExceptionType.invalidType, c.identifier, "Type does not match one specified in function signature.");
      }
    }

    return _current.find(c.identifier);
  }
}