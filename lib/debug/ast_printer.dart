import 'dart:io';

import 'package:nocturne_design/parse/expression.dart';
import 'package:nocturne_design/parse/statement.dart';

class AstPrinter {
  final Statement _root;
  int _indent;

  AstPrinter(this._root): _indent = 0;

  void print() {
    _printStatement(_root);
  }

  void _printStatement(Statement s) {
    switch (s) {
      case AssignStatement assign:
        _printAssign(assign);
        break;
      case BlockStatement block:
        _write("Block:");
        _indent++;
        for (Statement element in block.body) { _printStatement(element); }
        _indent--;
        break;
      case BreakStatement _:
        _write("Break;");
        break;
      case CallStatement call:
        _printCall(call);
        break;
      case DeclarationStatement decl:
        _printDeclaration(decl);
        break;
      case ForStatement forL:
        _printFor(forL);
        break;
      case FunctionStatement func:
        _printFunction(func);
        break;
      case IfStatement ifL:
        _printIf(ifL);
        break;
      case ReturnStatement ret:
        _printReturn(ret);
        break;
      case WhileStatement whileL:
        _printWhile(whileL);
        break;
      default:
        throw "Unimplemented statement";
    }
  }

  void _printAssign(AssignStatement a) {
    _write("Assign:");
    _indent++;

    _write("Left: ${a.left}");
    _write("Right:");
    _indent++;

    _printExpression(a.right);

    _indent -= 2;
  }

  void _printCall(CallStatement c) {
    _write("Call:");
    _indent++;

    _write("Identifier: ${c.identifier}");
    _write("Arguments:");
    _indent++;

    for (Expression element in c.arguments) { _printExpression(element); }

    _indent -= 2;
  }

  void _printDeclaration(DeclarationStatement d) {
    _write("Declaration:");
    _indent++;

    _write("Name: ${d.name}");
    _write("Type: ${d.type ?? "dynamic"}");
    _write("Properties: ${d.properties}");
    _write("Initializer:");
    _indent++;

    if (d.initializer != null) {
      _printExpression(d.initializer!);
    }
    else {
      _write("None");
    }

    _indent -= 2;
  }

  void _printFor(ForStatement f) {
    _write("For:");
    _indent++;

    _write("Initializer:");
    _indent++;
    _printDeclaration(f.initializer);
    _indent--;
    _write("Condition:");
    _indent++;
    _printExpression(f.condition);
    _indent--;
    _write("Increment:");
    _indent++;
    _printStatement(f.increment);
    _indent -= 2;
  }

  void _printFunction(FunctionStatement f) {
    _write("Function:");
    _indent++;

    _write("Name: ${f.name}");
    _write("Type: ${f.returnType ?? "dynamic"}");
    _write("Parameters:");
    _indent++;
    for (DeclarationStatement element in f.parameters) { _printDeclaration(element); }
    _indent--;

    _write("Body:");
    _indent++;
    _printStatement(f.body);
    _indent -= 2;
  }

  void _printIf(IfStatement i) {
    _write("If:");
    _indent++;

    _write("Condition:");
    _indent++;
    _printExpression(i.condition);
    _indent--;
    _write("If Branch:");
    _indent++;
    _printStatement(i.ifBranch);
    _indent--;
    _write("Else Branch:");
    _indent++;
    if (i.elseBranch != null) {
      _printStatement(i.elseBranch!);
    }
    else {
      _write("None");
    }
    _indent -= 2;
  }

  void _printReturn(ReturnStatement r) {
    _write("Return:");
    _indent++;

    _write("Value: ");
    _indent++;
    if (r.value != null) {
      _printExpression(r.value!);
    }
    else {
      _write("None");
    }
    _indent -= 2;
  }

  void _printWhile(WhileStatement w) {
    _write("While:");
    _indent++;

    _write("Condition:");
    _indent++;
    _printExpression(w.condition);
    _indent--;
    _write("Body:");
    _indent++;
    _printStatement(w.body);
    _indent -= 2;
  }

  void _printExpression(Expression e) {
    switch (e) {
      case AssignExpression assign:
        _printAssignExpression(assign);
        break;
      case BinaryExpression binary:
        _printBinary(binary);
        break;
      case CallExpression call:
        _printCallExpression(call);
        break;
      case GroupingExpression group:
        _write("Grouping:");
        _indent++;
        _printExpression(group.expression);
        _indent--;
        break;
      case LiteralExpression literal:
        _printLiteral(literal);
        break;
      case UnaryExpression unary:
        _printUnary(unary);
        break;
      case VarExpression varL:
        _printVar(varL);
        break;
    }
  }

  void _printAssignExpression(AssignExpression a) {
    _write("Assign:");
    _indent++;

    _write("Left: ${a.left}");
    _write("Right:");
    _indent++;

    _printExpression(a.right);

    _indent -= 2;
  }

  void _printBinary(BinaryExpression b) {
    _write("Binary:");
    _indent++;

    _write("Operator:");
    _indent++;
    _write(b.op.toString());
    _indent--;
    _write("Left:");
    _indent++;
    _printExpression(b.left);
    _indent--;
    _write("Right:");
    _indent++;
    _printExpression(b.right);
    _indent -= 2;
  }

  void _printCallExpression(CallExpression c) {
    _write("Call:");
    _indent++;

    _write("Identifier: ${c.identifier}");
    _write("Arguments:");
    _indent++;

    for (Expression element in c.arguments) { _printExpression(element); }

    _indent -= 2;
  }

  void _printLiteral(LiteralExpression l) {
    _write("Literal:");
    _indent++;
    _write(l.value.toString());
    _indent--;
  }

  void _printUnary(UnaryExpression u) {
    _write("Unary:");
    _indent++;

    _write("Operator:");
    _indent++;
    _write(u.op.lexeme);
    _indent--;
    _write("Right:");
    _indent++;
    _printExpression(u.right);
    _indent -= 2;
  }

  void _printVar(VarExpression v) {
    _write("Var:");
    _indent++;
    _write(v.identifier.toString());
    _indent--;
  }

  void _write(String s) {
    for (int i = 0; i < _indent; i++) {
      stdout.write("  ");
    }

    stdout.write("$s\n");
  }
}