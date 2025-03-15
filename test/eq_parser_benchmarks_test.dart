import 'package:eq_parser/eq_parser.dart' as p1;
import 'package:quds_formula_parser/quds_formula_parser.dart' as p2;
import 'package:formula_parser/formula_parser.dart' as p3;
import 'package:math_parser/math_parser.dart' as p4;
import 'package:math_expressions/math_expressions.dart' as p5;

import 'package:test/test.dart';

const executions = 100000;
const List<String> equations = [
  '23.6 * (5.6 + 2.4) / sin(3.2 ^ 3)',
  '93600 * tan(0.15) / 0.5',
  'sqrt(2) * (3.5 + 2 * (17 - 7.8)) ^ 7',
];

void main() {
  group('benchmarks', () {
    test('benchmarks', () {
      print('Starting benchmark');
      DateTime startAll = DateTime.now();
      DateTime start;

      // eq_parser
      print('eq_parser');
      num p1Result = 0;
      p1.EqParser p1Parser = p1.EqParser();
      start = DateTime.now();
      for (int i = 0; i < executions; i++) {
        for (String equation in equations) {
          p1Result = p1Parser.parse(equation);
        }
      }
      print('  ${DateTime.now().difference(start).inMilliseconds} ms');

      // QUDS Parser
      print('quds_formula_parser');
      p2.ValueWrapper<dynamic> p2Result;
      p2.FormulaParser p2Parser = p2.FormulaParser();
      p2.Formula f;
      p2.FormulaInfixToPostfixConvertor p2Supporter;
      start = DateTime.now();
      for (int i = 0; i < executions; i++) {
        for (String equation in equations) {
          f = p2Parser.parse(equation);
          p2Supporter = p2.FormulaInfixToPostfixConvertor(formula: f);
          p2Result = p2Supporter.evaluate();
        }
      }
      print('  ${DateTime.now().difference(start).inMilliseconds} ms');

      // formula_parser
      print('formula_parser');
      dynamic p3Result;
      start = DateTime.now();
      for (int i = 0; i < executions; i++) {
        for (String equation in equations) {
          var exp = p3.FormulaParser(equation);
          p3Result = exp.parse;
        }
      }
      print('  ${DateTime.now().difference(start).inMilliseconds} ms');

      // math_parser
      print('math_parser');
      num p4Result;
      start = DateTime.now();
      for (int i = 0; i < executions; i++) {
        for (String equation in equations) {
          p4Result = p4.MathNodeExpression.fromString(equation).calc(p4.MathVariableValues({}));
        }
      }
      print('  ${DateTime.now().difference(start).inMilliseconds} ms');

      // math_expressions
      print('math_expressions');
      dynamic p5Result;
      p5.Parser p5Parser = p5.Parser();
      p5.Expression p5Expression;
      p5.ContextModel cm = p5.ContextModel();
      start = DateTime.now();
      for (int i = 0; i < executions; i++) {
        for (String equation in equations) {
          p5Expression = p5Parser.parse(equation);
          p5Result = p5Expression.evaluate(p5.EvaluationType.REAL, cm);
        }
      }
      print('  ${DateTime.now().difference(start).inMilliseconds} ms');

      print('\nBenchmark completed in ${DateTime.now().difference(startAll).inMilliseconds} ms');

      expect(true, isTrue);
    });
  });
}