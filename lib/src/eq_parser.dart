import 'dart:math';

enum TokenType {
  unknown,
  number,
  operator,
  function,
  leftParenthesis,
  rightParenthesis,
  separator,
  eof,
  error
}

class Token {
  TokenType type = TokenType.unknown;
  String string = '';
  num value = 0;

  String function = '';
  List<dynamic>? params;

  int pos = 0;
}

/// Built-in functions
num abs(num x) => x.abs();
num floor(num x) => x.floor();
num ceil(num x) => x.ceil();
num round(num x) => x.round();
num trunc(num x) => x.truncate();
num rad(num x) => x * pi / 180;
num deg(num x) => x * 180 / pi;

/// A definition for a function
///
/// During parsing, the [function] is called. The number of parameters is checked before calling.
class FunctionDef {
  final Function function;
  final int paramCount;

  const FunctionDef(this.function, this.paramCount);

  num _apply(Token token) {
    if (token.params == null || token.params!.length != paramCount) {
      throw Exception(
          'Wrong number of parameters for function "${token.function}"');
    }
    return Function.apply(function, token.params!);
  }
}

/// Parser for mathematical equations
///
/// Implement the [onError] callback to handle errors. Add custom functions to the [functions] map. Add custom
/// references (variables) to the [references] map.
class EqParser {
  /// Built-in functions
  ///
  /// Custom functions may be added (or removed) before parsing. Function names are always lower case.
  final Map<String, FunctionDef> functions = {
    'sin': FunctionDef(sin, 1),
    'cos': FunctionDef(cos, 1),
    'tan': FunctionDef(tan, 1),
    'asin': FunctionDef(asin, 1),
    'acos': FunctionDef(acos, 1),
    'atan': FunctionDef(atan, 1),
    'sqrt': FunctionDef(sqrt, 1),
    'log': FunctionDef(log, 1),
    'abs': FunctionDef(abs, 1),
    'floor': FunctionDef(floor, 1),
    'ceil': FunctionDef(ceil, 1),
    'round': FunctionDef(round, 1),
    'truncate': FunctionDef(trunc, 1),
    'rad': FunctionDef(rad, 1),
    'deg': FunctionDef(deg, 1),
    'max': FunctionDef(max, 2),
    'min': FunctionDef(min, 2),
  };

  /// References (variables)
  ///
  /// Custom references may be added before parsing. These may be referenced in the equation using their name.
  /// Names are case-sensitive.
  final Map<String, num> references = {};

  /// Called when an error is encountered
  ///
  /// The error message and position within the equation string are passed as parameters.
  void Function(String, int)? onError;

  static const num _errorValue = double.nan;
  String _str = '';
  int _pos = 0;
  final List<Token> _stack = [];

  /// Parse an equation from a string
  ///
  /// onError is called when an error is encountered, and double.nan is returned.
  /// Otherwise the result of the equation is returned.
  num parse(String equation) {
    _stack.clear();
    _str = equation;
    _pos = 0;

    while (true) {
      // Read a token.
      Token token = _readToken();
      if (token.type == TokenType.eof) {
        break;
      } else if (token.type == TokenType.error) {
        return _errorValue;
      }
      if (!_push(token)) {
        return _errorValue;
      }
    }
    if (!_processStack()) {
      return _errorValue;
    }
    if (_stack.length != 1) {
      if (onError != null) {
        onError!('Equation could not be parsed correctly', 0);
      }
      return _errorValue;
    }

    return _stack[0].value;
  }

  /// Add a token to the stack and process it if required
  bool _push(Token token) {
    switch (token.type) {
      case TokenType.number || TokenType.leftParenthesis || TokenType.function:
        _stack.add(token);
        break;

      case TokenType.operator:
        // Operator must follow a number, unless it's the 'negative' sign
        if (_stack.isEmpty || _stack.last.type != TokenType.number) {
          if (token.string == '-') {
            _stack.add(Token()
              ..type = TokenType.number
              ..value = 0);
          } else {
            if (onError != null) {
              onError!(
                  'Operator "${token.string}" must follow a number', token.pos);
            }
            return false;
          }
        }
        while ((_stack.length > 2) &&
            _hasPrecedence(token, _stack[_stack.length - 2])) {
          if (!_processStack(limit: 1)) {
            return false;
          }
        }
        _stack.add(token);
        break;

      case TokenType.rightParenthesis:
        // Process backwards to opening bracket
        int stackLen = 0;
        while (true) {
          if (_stack.isEmpty) {
            if (onError != null) {
              onError!('Matching "(" not found', token.pos);
            }
            return false;
          } else if (_stack.last.type == TokenType.leftParenthesis) {
            _stack.removeLast();
            break;
          } else if (_stack.length > 1 &&
              _stack[_stack.length - 2].type == TokenType.leftParenthesis) {
            _stack.removeAt(_stack.length - 2);
            break;
          } else if (_stack.length > 1 &&
              _stack[_stack.length - 2].type == TokenType.function) {
            _stack[_stack.length - 2].params!.add(_stack.removeLast().value);
            if (!_processFunction(_stack.last)) {
              return false;
            }
            break;
          } else {
            if (!_processStack()) {
              return false;
            }
            if (stackLen > 0 && _stack.length == stackLen) {
              if (onError != null) {
                onError!('Error processing ")"', token.pos);
              }
              return false;
            }
            stackLen = _stack.length;
          }
        }
        break;

      case TokenType.separator:
        // Process backwards to function
        int stackLen = 0;
        while (true) {
          if (_stack[_stack.length - 2].type == TokenType.function) {
            _stack[_stack.length - 2].params!.add(_stack.removeLast().value);
            break;
          } else {
            if (!_processStack()) {
              return false;
            }
            if (stackLen > 0 && _stack.length == stackLen) {
              if (onError != null) {
                onError!('Error processing ","', token.pos);
              }
              return false;
            }
            stackLen = _stack.length;
          }
        }
        break;

      default:
        if (onError != null) {
          onError!('Unexpected token "${token.string}"', token.pos);
        }
        return false;
    }
    return true;
  }

  /// Looks at the top 3 elements on the stack and processes them if they are
  /// a group of [number, operator, number]
  bool _processStack({int limit = -1}) {
    while (_stack.length > 2 && limit-- != 0) {
      if (_stack[_stack.length - 3].type == TokenType.number &&
          _stack[_stack.length - 2].type == TokenType.operator &&
          _stack[_stack.length - 1].type == TokenType.number) {
        if (!_applyOperator(
            _stack.removeLast(), _stack.removeLast(), _stack.last)) {
          return false;
        }
      } else {
        break;
      }
    }
    return true;
  }

  bool _processFunction(Token token) {
    if (functions.containsKey(token.function)) {
      token.value = functions[token.function]!._apply(token);
      token.type = TokenType.number;
    } else {
      if (onError != null) {
        onError!('Unknown function "${token.function}"', token.pos);
      }
      return false;
    }
    return true;
  }

  bool _applyOperator(Token token2, Token operator, Token token) {
    switch (operator.string) {
      case '+':
        token.value = token.value + token2.value;
        break;
      case '-':
        token.value = token.value - token2.value;
        break;
      case '*':
        token.value = token.value * token2.value;
        break;
      case '/':
        token.value = token.value / token2.value;
        break;
      case '^':
        token.value = pow(token.value, token2.value);
        break;
      case '%':
        token.value = token.value % token2.value;
        break;
      default:
        if (onError != null) {
          onError!('Unknown operator "${operator.string}"', operator.pos);
        }
        return false;
    }
    return true;
  }

  /// Return true if the operator represented in token1 has precedence over token2
  bool _hasPrecedence(Token token1, Token token2) {
    return _operatorOrder(token1) < _operatorOrder(token2);
  }

  /// Return the precedence order of an operator
  int _operatorOrder(Token t) {
    if (t.type == TokenType.leftParenthesis) {
      return 1;
    } else if (t.type == TokenType.operator) {
      switch (t.string) {
        case '+' || '-':
          return 2;
        case '*' || '/':
          return 3;
        case '^' || '%':
          return 4;
      }
    }
    return 0;
  }

  /// Read the next token from the string
  ///
  /// Will read a token and interpret it's type and value
  Token _readToken() {
    Token token = Token();
    bool started = false;

    while (true) {
      if (_pos >= _str.length) {
        token.type = TokenType.eof;
        break;
      }

      String c = _str[_pos++];

      // Ignore whitespace if not yet started
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        if (started) {
          break;
        } else {
          continue;
        }
      } else if (c == '(') {
        if (started) {
          if (functions.containsKey(token.string.toLowerCase())) {
            token.type = TokenType.function;
            token.function = token.string.toLowerCase();
            token.params = [];
            token.pos = _pos;
            started = false;
          } else {
            _pos--;
          }
          break;
        }
        token.type = TokenType.leftParenthesis;
        token.pos = _pos;
        break;
      } else if (c == ')') {
        token.type = TokenType.rightParenthesis;
        token.pos = _pos;
        if (started) {
          _pos--;
          break;
        }
        break;
      } else if (c == '+' ||
          c == '-' ||
          c == '*' ||
          c == '/' ||
          c == '^' ||
          c == '%') {
        if (started) {
          _pos--;
          break;
        }
        token.type = TokenType.operator;
        token.string = c;
        token.pos = _pos;
        break;
      } else if (c == ',') {
        if (started) {
          _pos--;
          break;
        }
        token.type = TokenType.separator;
        token.pos = _pos;
        break;
      } else {
        if (!started) {
          started = true;
          token.pos = _pos;
        }
        token.string += c;
      }
    }
    // Try to determine the type and value
    while (started) {
      num? i = num.tryParse(token.string);
      if (i != null) {
        token.type = TokenType.number;
        token.value = i;
        break;
      }
      if (token.string.toLowerCase() == 'pi') {
        token.type = TokenType.number;
        token.value = pi;
        break;
      }
      if (token.string.toLowerCase().startsWith('0b')) {
        token.type = TokenType.number;
        token.value = int.parse(token.string.substring(2), radix: 2);
        break;
      }
      if (references.containsKey(token.string)) {
        token.type = TokenType.number;
        token.value = references[token.string]!;
        break;
      }
      if (onError != null) {
        onError!('Unknown token "${token.string}"', token.pos);
      }
      token.type = TokenType.error;
      break;
    }

    return token;
  }
}
