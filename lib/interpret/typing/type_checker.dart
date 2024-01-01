import 'package:nocturne_design/interpret/native_methods.dart';
import 'package:nocturne_design/interpret/resolving/resolver.dart';
import 'package:nocturne_design/interpret/resolving/resolving_exception.dart';
import 'package:nocturne_design/interpret/symbols/symbol.dart';
import 'package:nocturne_design/interpret/typing/type.dart';
import 'package:nocturne_design/lex/token.dart';
import 'package:nocturne_design/parse/statement.dart';

Map<String, NType> _typeDict = {
  "dynamic": NType(0, 0, false),
  "string": NType(1, 0, false),
  "int": NType(2, 8, true),
  "real": NType(3, 8, true),
  "bool": NType(4, 1, true),
  "void": NType(5, 0, true),
  "null": NType(6, 0, true)
};

void declareType(Token key, StructStatement s) {
  if (_typeDict.containsKey(key.tokenValue)) {
    throw ResolvingException(ResolvingExceptionType.typeOverlap, key, "Duplicate type declaration.");
  }

  int size = 0;
  bool fixedSize = true;

  for (DeclarationStatement decl in s.properties) {
    if (!_fromToken(decl.type).fixedSize) {
      fixedSize = false;
      break;
    }

    size += _fromToken(decl.type).byteSize;
  }

  _typeDict[key.tokenValue] = NType(_typeDict.length, size, fixedSize);
}

NType _fromToken(Token? type) {
  return _typeDict[type?.tokenValue ?? "dynamic"]!;
}

bool typesMatchT(NType left, NSymbol right) {
  if (evaluateType(right).signature == _typeDict["dynamic"]!.signature) {
    return true;
  }
  return left.signature == evaluateType(right).signature;
}

bool typesMatch(NSymbol left, NSymbol right) {
  if ((evaluateType(left).signature == _typeDict["dynamic"]!.signature) || (evaluateType(right).signature == _typeDict["dynamic"]!.signature)) {
    return true;
  }
  return evaluateType(left).signature == evaluateType(right).signature;
}

NType evaluateType(NSymbol s) {
  switch (s) {
    case FunctionSymbol func:
      return getType(func.type?.lexeme ?? "dynamic", s.type);
    case VariableSymbol varL:
      return getType(varL.type?.lexeme ?? "dynamic", varL.type);
    case LiteralSymbol literal:
      return _evaluateLiteral(literal);
    case NativeVariableSymbol nVar:
      return nVar.type;
    case NativeFunctionSymbol nFunc:
      return nFunc.returnType;
    case ConstructorSymbol con:
      return getTypeF(con.type!.lexeme);
    default:
      throw ResolvingException(ResolvingExceptionType.noAssociatedType, s.blame, "No type associated with ${s.blame.lexeme}.");
  }
}

NType _evaluateLiteral(LiteralSymbol l) {
  switch (l.value) {
    case int _:
      return getType("int", l.blame);
    case double _:
      return getType("real", l.blame);
    case bool _:
      return getType("bool", l.blame);
    case null:
      return getType("null", l.blame);
    case String _:
      return getType("string", l.blame);
    default:
      throw ResolvingError("Unhandled literal type.");
  }
}

NType getType(String s, Token? o) {
  if (_typeDict.containsKey(s)) {
    return _typeDict[s]!;
  }

  throw ResolvingException(ResolvingExceptionType.invalidType, o!, "Type $s does not exist.");
}

NType getTypeF(String s) {
  if (_typeDict.containsKey(s)) {
    return _typeDict[s]!;
  }

  throw ResolvingError("Type $s does not exist.");
}

bool typeExists(String s) {
  return _typeDict.containsKey(s);
}