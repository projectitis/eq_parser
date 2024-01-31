import 'package:eq_parser/eq_parser.dart';
import 'dart:math';

void main() {

  var parser = EqParser();
  
  // Built-ins only
  num result1 = parser.parse('12 + 3 ^ (5.12 * sin(pi/2))');
  print(result1); // 289.24314972238506

  // Custom references (variables) and function
  parser.references.addAll({
    'dozen': 12,
    'factor': 5.12,
  });
  parser.functions['pow3'] = FunctionDef((v)=>pow(3, v), 1);
  num result2 = parser.parse('dozen + pow3(factor * sin(pi/2))');
  print(result2); // 289.24314972238506

  print(result1 == result2); // true
}
