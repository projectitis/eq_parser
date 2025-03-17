A light, fast equation parser that supports functions and variables.

## Features

- Supports many number formats. E.g.:
  - `12`
  - `-1.234`
  - `1.234e5`
  - `0xff12`
  - `0b1101101`
- Mathematical operators and brackets
  - `+` `-` `*` `/` `^` `%` `(` `)`
- Common functions are built-in
  - `sin`, `acos`, `max`, `min`, `floor`, `round`, `log`, etc
- Supports user-defined functions
- Supports user-defined variables (references)
- User-defined error handling
- Fast (see [benchmark results](#benchmark-results))

## Getting started

- Add `eq_parser` to your `pubspec.yaml`
- Add `import 'package:eq_parser/eq_parser.dart';` to your code

## Usage

```dart
num result = EqParser()..parse('12 + 3 ^ (5.12 * sin(pi/2))');
```

```dart
var parser = EqParser();
parser.onError = (m, p)=>throw Exception('$m at position $p');
parser.references.addAll({
    'x': 3,
    'y': 4,
});
parser.functions['multiply'] = FunctionDef((a, b)=>a * b, 2);
num result = parser.parse('multiply(x, y)');
```

## Additional information

Although not using any existing technique as a reference, this parser is
very likely an implementation of operator precedence parsing, such as Pratt
Parsing. I have not studied parsing techniques, but reading summaries online
it appears to work in the same way, without creating an intermediary format
such as Reverse Polish Notation. 

Tokens are pushed to the stack just once, and popped/processed just once, so
performance is fast (see [benchmarks](#benchmark-results)) and linear with
respect to the length of the equation.

There is a minimal implementation included for reference purposes. It can be
used like this:

```dart
import 'package:eq_parser/src/eq_parser_lite.dart';

num result = EqParserLite()..parse('(17 - 7.12) * 2 ^ 4');
```

## Benchmark results

Benchmarks are in the test folder and are run as part of test execution.
EqParser is compared against several other equation/formula parsing libraries.
Please let me know if you would like any other parsers compared, or if any of
the tests for the other packages are incorrect or are unfairly un-optimised.

### Results

Lower is better.

| Parser             | Time (ms) | Faster |
|--------------------|-----------|--------|
| __eq_parser__      | __774__   |        |
| formula_parser     | 4933      | 6.4x   |
| math_expressions   | 6228      | 8.0x   |
| math_parser        | 6698      | 8.7x   |
| quds_formula_parser| 19954     | 25.8x  |

### Running the benchmarks

```dart
dart test .\test\eq_parser_benchmarks_test.dart
```
