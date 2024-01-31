import 'package:eq_parser/eq_parser.dart';
import 'package:test/test.dart';
import 'dart:math';

void main() {
  group('types', () {
    test('integer', () {
      var parser = EqParser();
      num result = parser.parse('12');

      expect(result, equals(12));
    });

    test('float', () {
      var parser = EqParser();
      num result = parser.parse('1.21');

      expect(result, equals(1.21));
    });

    test('hex', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('0xff');
      expect(result, equals(255));

      result = parser.parse('0xFF');
      expect(result, equals(255));

      result = parser.parse('0Xff');
      expect(result, equals(255));

      result = parser.parse('0XFF');
      expect(result, equals(255));
    });

    test('binary', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('0b10101');
      expect(result, equals(21));

      result = parser.parse('0B10101');
      expect(result, equals(21));
    });
  });

  group('simple operations', () {
    test('addition', () {
      var parser = EqParser();
      num result = parser.parse('1 + 2.3');

      expect(result, equals(1 + 2.3));
    });

    test('subtraction', () {
      var parser = EqParser();
      num result = parser.parse('1 - 2.3');

      expect(result, equals(1 - 2.3));
    });

    test('negative integer', () {
      var parser = EqParser();
      // Same as "0 - 2345"
      num result = parser.parse('-2345');

      expect(result, equals(-2345));
    });

    test('negative float', () {
      var parser = EqParser();
      // Same as "0 - 23.45"
      num result = parser.parse('-23.45');

      expect(result, equals(-23.45));
    });

    test('subtracting a negative number', () {
      var parser = EqParser();
      num result = parser.parse('1 - -2.3');

      expect(result, equals(1 - -2.3));
    });

    test('multiplication', () {
      var parser = EqParser();
      num result = parser.parse('3.2 * 4.004');

      expect(result, equals(3.2 * 4.004));
    });

    test('division', () {
      var parser = EqParser();
      num result = parser.parse('3.2 / 4.004');

      expect(result, equals(3.2 / 4.004));
    });

    test('power', () {
      var parser = EqParser();
      num result = parser.parse('6 ^ 2');

      expect(result, equals(pow(6, 2)));
    });

    test('modulo', () {
      var parser = EqParser();
      num result = parser.parse('6.133 % 3');

      expect(result, equals(6.133 % 3));
    });
  });

  group('order', () {
    test('addition and multiplication', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('3 * 2 + 7');
      expect(result, equals(3 * 2 + 7));

      result = parser.parse('3 + 2 * 7');
      expect(result, equals(3 + 2 * 7));
    });

    test('subtraction and division', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('3 / 2 - 7');
      expect(result, equals(3 / 2 - 7));

      result = parser.parse('3 - 2 / 7');
      expect(result, equals(3 - 2 / 7));
    });

    test('multiplication and power', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('3 * 2 ^ 7');
      expect(result, equals(3 * pow(2, 7)));

      result = parser.parse('3 ^ 2 * 7');
      expect(result, equals(pow(3, 2) * 7));
    });

    test('power associativity', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('3 ^ 2 ^ 7');
      expect(result, equals(pow(3, pow(2, 7))));
    });

    test('simple brackets', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('3 * (2 + 7)');
      expect(result, equals(3 * (2 + 7)));
    });

    test('multiple bracket groups', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('3 * (2 + 7) * (1 + 2)');
      expect(result, equals(3 * (2 + 7) * (1 + 2)));
    });

    test('nested brackets', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('3 * (2 * (1 + 2))');
      expect(result, equals(3 * (2 * (1 + 2))));
    });

    test('multiple nested bracket groups', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('3 * ((2 ^ (7 - 2)) * (1 + 2))');
      expect(result, equals(3 * ((pow(2, (7 - 2))) * (1 + 2))));
    });
  });

  group('formatting', () {
    test('whitespace', () {
      var parser = EqParser();
      num result = parser.parse('   1 +2.3\t');

      expect(result, equals(1 + 2.3));
    });

    test('no whitespace', () {
      var parser = EqParser();
      // Same as: 1 - -2.3
      num result = parser.parse('1--2.3');

      expect(result, equals(1 - -2.3));
    });
  });

  group('functions', () {
    test('single param', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('sin(pi)');
      expect(result, equals(sin(pi)));

      result = parser.parse('cos( 0.1234 )');
      expect(result, equals(cos(0.1234)));
    });

    test('multi param', () {
      var parser = EqParser();
      num result = 0;

      result = parser.parse('max(200, 100)');
      expect(result, equals(max(200, 100)));

      result = parser.parse('min(200, 100)');
      expect(result, equals(min(200, 100)));
    });

    test('custom', () {
      var parser = EqParser();
      parser.functions['f'] = FunctionDef((v) => v * 2, 1);

      num result = parser.parse('f(3.78)');
      expect(result, equals(3.78 * 2));
    });
  });

  group('references', () {
    test('single param', () {
      var parser = EqParser();
      parser.references.addAll({
        'dozen': 12,
        'factor': 5.12,
      });

      num result = parser.parse('dozen + 3 ^ (factor * sin(pi/2))');
      expect(result, equals(12 + pow(3, (5.12 * sin(pi / 2)))));
    });
  });

  group('errors', () {
    test('invalid operations', () {
      int errorCount = 0;
      var parser = EqParser();
      parser.onError = (m, p) => errorCount++;
      num result = 0;

      result = parser.parse('12 23');
      expect(result, isNaN);
      expect(errorCount, greaterThan(0));

      errorCount = 0;
      result = parser.parse('12 + (3 * 2');
      expect(result, isNaN);
      expect(errorCount, greaterThan(0));

      errorCount = 0;
      result = parser.parse('12 + (3 * 2))');
      expect(result, isNaN);
      expect(errorCount, greaterThan(0));

      errorCount = 0;
      result = parser.parse(')');
      expect(result, isNaN);
      expect(errorCount, greaterThan(0));

      errorCount = 0;
      result = parser.parse('12 + foobar');
      expect(result, isNaN);
      expect(errorCount, greaterThan(0));

      errorCount = 0;
      result = parser.parse('11 ** 2');
      expect(result, isNaN);
      expect(errorCount, greaterThan(0));
    });
  });
}
