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

## Getting started

- Add `eq_parser` to your `pubspec.yaml`

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

This parser is not based on the shunting yard algorithm or reverse polish
notation. I am not sure if it actually matches any existing algorithm or if
it is novel. It's based on a single stack, and does not use recursion. Tokens
are pushed to the stack just once, and popped/processed just once, so performance is
fast and linear with respect to the length of the equation.
