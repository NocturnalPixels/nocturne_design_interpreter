import 'package:enum_flag/enum_flag.dart';
import 'package:nocturne_design/interpret/environment.dart';
import 'package:nocturne_design/interpret/native_methods.dart';
import 'package:nocturne_design/interpret/resolving/resolving_exception.dart';
import 'package:nocturne_design/interpret/symbols/symbol.dart';
import 'package:nocturne_design/interpret/typing/type_checker.dart';
import 'package:nocturne_design/lex/token.dart';
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

  int _unnamedEnvCount;

  Resolver(this._statements, this._current): _currentFunc = null, _unnamedEnvCount = 0;

  void resolve() {
    for (Statement element in _statements) { _statement(element); }
  }

  void _statement(Statement s) {
    switch (s) {
      case AssignStatement assign:
        _assign(assign);
        break;
      case BlockStatement block:
        BlockSymbol s = _current.findF((_unnamedEnvCount++).toString()) as BlockSymbol;
        _current = s.env;
        for (Statement element in block.body) { _statement(element); }
        _current = _current.exit();
        break;
      case CallStatement call:
        _call(call);
        break;
      case DeclarationStatement decl:
        _declaration(decl);
        break;
      case ForStatement forL:
        _for(forL);
        break;
      case FunctionStatement function:
        _function(function);
        break;
      case IfStatement ifL:
        _if(ifL);
        break;
      case ReturnStatement ret:
        _return(ret);
        break;
      case WhileStatement whileL:
        _while(whileL);
        break;

      case BreakStatement _:
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

  void _declaration(DeclarationStatement d) {
    VariableSymbol v = _current.find(d.name) as VariableSymbol;

    if (d.initializer != null) {
      if (!typesMatch(v, _expression(d.initializer!))) {
        throw ResolvingException(ResolvingExceptionType.typeMismatch, v.blame, "Initializer type does not match declaration.");
      }
    }
  }

  void _for(ForStatement f) {
    EnvironmentSymbol e = _current.findF((_unnamedEnvCount++).toString()) as EnvironmentSymbol;
    _current = e.env;

    if (!typesMatchT(getTypeF("bool"), _expression(f.condition))) {
      throw ResolvingException(ResolvingExceptionType.typeMismatch, f.blame, "For condition does not evaluate to boolean.");
    }

    _statement(f.body);
    _current = _current.exit();
  }

  void _function(FunctionStatement f) {
    _currentFunc = _current.find(f.name) as FunctionSymbol;
    _current = _currentFunc!.env;

    _statement(f.body);

    _currentFunc = null;
  }

  void _if(IfStatement i) {
    EnvironmentSymbol ifBranch = _current.findF((_unnamedEnvCount++).toString()) as EnvironmentSymbol;
    int elseIndex = _unnamedEnvCount++;

    if (!typesMatchT(getTypeF("bool"), _expression(i.condition))) {
      throw ResolvingException(ResolvingExceptionType.typeMismatch, i.blame, "For condition does not evaluate to boolean.");
    }

    _current = ifBranch.env;
    _statement(i.ifBranch);
    _current = _current.exit();
    if (i.elseBranch != null) {
      EnvironmentSymbol elseBranch = _current.findF(elseIndex.toString()) as EnvironmentSymbol;
      _current = elseBranch.env;
      _statement(i.elseBranch!);
      _current = _current.exit();
    }
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

  void _while(WhileStatement w) {
    EnvironmentSymbol e = _current.findF((_unnamedEnvCount++).toString()) as EnvironmentSymbol;
    _current = e.env;

    if (!typesMatchT(getTypeF("bool"), _expression(w.condition))) {
      throw ResolvingException(ResolvingExceptionType.typeMismatch, w.blame, "For condition does not evaluate to boolean.");
    }

    _statement(w.body);

    _current = _current.exit();
  }

  NSymbol _expression(Expression e) {
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
        return LiteralSymbol(literal.blame, literal.value);
      case VarExpression varL:
        return _current.find(varL.identifier);
      case UnaryExpression unary:
        return _unary(unary);
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

  NSymbol _binary(BinaryExpression b) {
    NSymbol left = _expression(b.left);
    NSymbol right = _expression(b.right);
    NSymbol op = _current.find(b.op);

    if (op is FunctionSymbol) {
      if (op.params.length != 2) {
        throw ResolvingException(ResolvingExceptionType.invalidArgumentCount, op.blame, "Inline call requires precisely 2 arguments.");
      }

      if (!typesMatch(left, op.params[0])) {
        throw ResolvingException(ResolvingExceptionType.typeMismatch, left.blame, "Type does not match type specified in function signature.");
      }

      if (!typesMatch(right, op.params[1])) {
        throw ResolvingException(ResolvingExceptionType.typeMismatch, left.blame, "Type does not match type specified in function signature.");
      }
    }

    return op;
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

    return s;
  }

  NSymbol _unary(UnaryExpression u) {
    NSymbol v = _expression(u.right);

    if (u.op.tokenType == TokenType.bang) {
      if (!typesMatchT(getTypeF("bool"), v)) {
        throw ResolvingException(ResolvingExceptionType.typeMismatch, u.op, "Not operator requires boolean value.");
      }
    }
    else if (u.op.tokenType == TokenType.minus) {
      if (!typesMatchT(getTypeF("int"), v) && !typesMatchT(getTypeF("real"), v)) {
        throw ResolvingException(ResolvingExceptionType.typeMismatch, u.op, "Negation operator requires numeric value.");
      }
    }

    return v;
  }
}