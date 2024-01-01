import 'package:nocturne_design/lex/token.dart';

abstract class Expression {
  const Expression();
}

class AssignExpression extends Expression {
  final Token left;
  final Expression right;

  const AssignExpression(this.left, this.right);
}

class BinaryExpression extends Expression {
  final Token op;
  final Expression left, right;

  const BinaryExpression(this.op, this.left, this.right);
}

class CallExpression extends Expression {
  final Token identifier;
  final List<Expression> arguments;

  const CallExpression(this.identifier, this.arguments);
}

class GroupingExpression extends Expression {
  final Expression expression;

  const GroupingExpression(this.expression);
}

class LiteralExpression extends Expression {
  final Token blame;
  final dynamic value;

  const LiteralExpression(this.blame, this.value);
}

class UnaryExpression extends Expression {
  final Token op;
  final Expression right;

  const UnaryExpression(this.op, this.right);
}

class VarExpression extends Expression {
  final Token identifier;

  const VarExpression(this.identifier);
}

class AccessorExpression extends Expression {
  final Expression left;
  final Expression right;

  const AccessorExpression(this.left, this.right);
}