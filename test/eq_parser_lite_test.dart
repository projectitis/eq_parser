import 'package:eq_parser/src/eq_parser_lite.dart';
import 'package:test/test.dart';
import 'dart:math';

void main() {
  group('types', () {
    test('integer', () {
      var parser = EqParserLite();
      num result = parser.parse('12');

      expect(result, equals(12));
    });

    test('float', () {
      var parser = EqParserLite();
      num result = parser.parse('1.21');

      expect(result, equals(1.21));
    });

    test('hex', () {
      var parser = EqParserLite();
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
      var parser = EqParserLite();
      num result = 0;

      result = parser.parse('0b10101');
      expect(result, equals(21));

      result = parser.parse('0B10101');
      expect(result, equals(21));
    });
  });

  group('simple operations', () {
    test('addition', () {
      var parser = EqParserLite();
      num result = parser.parse('1 + 2.3');

      expect(result, equals(1 + 2.3));
    });

    test('subtraction', () {
      var parser = EqParserLite();
      num result = parser.parse('1 - 2.3');

      expect(result, equals(1 - 2.3));
    });

    test('negative integer', () {
      var parser = EqParserLite();
      // Same as "0 - 2345"
      num result = parser.parse('-2345');

      expect(result, equals(-2345));
    });

    test('negative float', () {
      var parser = EqParserLite();
      // Same as "0 - 23.45"
      num result = parser.parse('-23.45');

      expect(result, equals(-23.45));
    });

    test('subtracting a negative number', () {
      var parser = EqParserLite();
      num result = parser.parse('1 - -2.3');

      expect(result, equals(1 - -2.3));
    });

    test('multiplication', () {
      var parser = EqParserLite();
      num result = parser.parse('3.2 * 4.004');

      expect(result, equals(3.2 * 4.004));
    });

    test('division', () {
      var parser = EqParserLite();
      num result = parser.parse('3.2 / 4.004');

      expect(result, equals(3.2 / 4.004));
    });

    test('power', () {
      var parser = EqParserLite();
      num result = parser.parse('6 ^ 2');

      expect(result, equals(pow(6, 2)));
    });

    test('modulo', () {
      var parser = EqParserLite();
      num result = parser.parse('6.133 % 3');

      expect(result, equals(6.133 % 3));
    });
  });

  group('order', () {
    test('addition and multiplication', () {
      var parser = EqParserLite();
      num result = 0;

      result = parser.parse('3 * 2 + 7');
      expect(result, equals(3 * 2 + 7));

      result = parser.parse('3 + 2 * 7');
      expect(result, equals(3 + 2 * 7));
    });

    test('subtraction and division', () {
      var parser = EqParserLite();
      num result = 0;

      result = parser.parse('3 / 2 - 7');
      expect(result, equals(3 / 2 - 7));

      result = parser.parse('3 - 2 / 7');
      expect(result, equals(3 - 2 / 7));
    });

    test('multiplication and power', () {
      var parser = EqParserLite();
      num result = 0;

      result = parser.parse('3 * 2 ^ 7');
      expect(result, equals(3 * pow(2, 7)));

      result = parser.parse('3 ^ 2 * 7');
      expect(result, equals(pow(3, 2) * 7));
    });

    test('power associativity', () {
      var parser = EqParserLite();
      num result = 0;

      result = parser.parse('3 ^ 2 ^ 7');
      expect(result, equals(pow(3, pow(2, 7))));
    });

    test('simple brackets', () {
      var parser = EqParserLite();
      num result = 0;

      result = parser.parse('3 * (2 + 7)');
      expect(result, equals(3 * (2 + 7)));
    });

    test('multiple bracket groups', () {
      var parser = EqParserLite();
      num result = 0;

      result = parser.parse('3 * (2 + 7) * (1 + 2)');
      expect(result, equals(3 * (2 + 7) * (1 + 2)));
    });

    test('nested brackets', () {
      var parser = EqParserLite();
      num result = 0;

      result = parser.parse('3 * (2 * (1 + 2))');
      expect(result, equals(3 * (2 * (1 + 2))));
    });

    test('multiple nested bracket groups', () {
      var parser = EqParserLite();
      num result = 0;

      result = parser.parse('3 * ((2 ^ (7 - 2)) * (1 + 2))');
      expect(result, equals(3 * ((pow(2, (7 - 2))) * (1 + 2))));
    });
  });

  group('formatting', () {
    test('whitespace', () {
      var parser = EqParserLite();
      num result = parser.parse('   1 +2.3\t');

      expect(result, equals(1 + 2.3));
    });

    test('no whitespace', () {
      var parser = EqParserLite();
      // Same as: 1 - -2.3
      num result = parser.parse('1--2.3');

      expect(result, equals(1 - -2.3));
    });

    test('newline', () {
      var parser = EqParserLite();
      num result = parser.parse('''

3 * ((2 ^ (7 - 
2)) * (1 + 2)

)''');

      expect(result, equals(3 * ((pow(2, (7 - 2))) * (1 + 2))));
    });
  });
}
