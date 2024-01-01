import 'package:enum_flag/enum_flag.dart';
import 'package:nocturne_design/lex/token.dart';
import 'package:nocturne_design/parse/expression.dart';

enum Properties with EnumFlag {
  constant,
  arrayType,
}

abstract class Statement {
  final int uid;

  const Statement(this.uid);
}

class AssignStatement extends Statement {
  final Token left;
  final Expression right;

  const AssignStatement(this.left, this.right, super.uid);
}

class BlockStatement extends Statement {
  final List<Statement> body;
  final Token blame;

  const BlockStatement(this.body, this.blame, super.uid);
}

class BreakStatement extends Statement {
  const BreakStatement(super.uid);
}

class CallStatement extends Statement {
  final Token identifier;
  final List<Expression> arguments;

  const CallStatement(this.identifier, this.arguments, super.uid);
}

class DeclarationStatement extends Statement {
  final Token name;
  final Token? type;
  final Expression? initializer;
  final int properties;

  const DeclarationStatement(this.name, this.type, this.initializer, this.properties, super.uid);
}

class ForStatement extends Statement {
  final DeclarationStatement initializer;
  final Expression condition;
  final Statement increment;
  final Statement body;
  final Token blame;

  const ForStatement(this.initializer, this.condition, this.increment, this.body, this.blame, super.uid);
}

class FunctionStatement extends Statement {
  final Token name;
  final Token? returnType;
  final List<DeclarationStatement> parameters;
  final Statement body;

  const FunctionStatement(this.name, this.returnType, this.parameters, this.body, super.uid);
}

class IfStatement extends Statement {
  final Expression condition;
  final Statement ifBranch;
  final Statement? elseBranch;
  final Token blame;

  const IfStatement(this.condition, this.ifBranch, this.elseBranch, this.blame, super.uid);
}

class ModStatement extends Statement {
  final Token name;
  final List<FunctionStatement> methods;

  const ModStatement(this.name, this.methods, super.uid);
}

class StructStatement extends Statement {
  final Token name;
  final List<DeclarationStatement> properties;

  const StructStatement(this.name, this.properties, super.uid);
}

class ReturnStatement extends Statement {
  final Token blame;
  final Expression? value;

  const ReturnStatement(this.blame, this.value, super.uid);
}

class WhileStatement extends Statement {
  final Expression condition;
  final Statement body;
  final Token blame;

  const WhileStatement(this.condition, this.body, this.blame, super.uid);
}

class AccessorStatement extends Statement {
  final Expression left;
  final Expression right;

  const AccessorStatement(this.left, this.right, super.uid);
}