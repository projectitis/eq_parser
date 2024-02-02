import 'dart:math';

enum TokenType {
  unknown,
  number,
  operator,
  leftParenthesis,
  rightParenthesis,
  eof
}

class Token {
  TokenType type = TokenType.unknown;
  String string = '';

  num value = 0;
}

/// Parser for mathematical equations
///
/// This is a minimal implementation of EqParser. It omits support for variables and custom functions,
/// and does not support error handling. It is intended for use in situations where the equation is
/// known, or as a reference to understand the parsing algorithm.
class EqParserLite {
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
      Token token = _readToken();
      if (token.type == TokenType.eof) {
        break;
      }
      _push(token);
    }
    _processStack();

    return _stack.first.value;
  }

  /// Add a token to the stack and process it if required
  void _push(Token token) {
    switch (token.type) {
      case TokenType.number || TokenType.leftParenthesis:
        _stack.add(token);
        break;

      case TokenType.operator:
        // Operator must follow a number, unless it's the 'negative' sign
        if (_stack.isEmpty || _stack.last.type != TokenType.number) {
          if (token.string == '-') {
            _stack.add(Token()
              ..type = TokenType.number
              ..value = 0);
          }
        }
        while ((_stack.length > 2) &&
            _hasPrecedence(token, _stack[_stack.length - 2])) {
          _processStack(limit: 1);
        }
        _stack.add(token);
        break;

      case TokenType.rightParenthesis:
        // Process backwards to opening bracket
        while (true) {
          if (_stack.last.type == TokenType.leftParenthesis) {
            _stack.removeLast();
            break;
          } else if (_stack.length > 1 &&
              _stack[_stack.length - 2].type == TokenType.leftParenthesis) {
            _stack.removeAt(_stack.length - 2);
            break;
          } else {
            _processStack();
          }
        }
        break;

      default:
        break;
    }
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

  // Performs a mathematical operation on two tokens
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
        break;
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

  /// Read the next token from the string and interpret it's value
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
          _pos--;
          break;
        }
        token.type = TokenType.leftParenthesis;
        break;
      } else if (c == ')') {
        token.type = TokenType.rightParenthesis;
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
        break;
      } else {
        if (!started) {
          started = true;
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
      token.type = TokenType.eof;
      break;
    }
    return token;
  }
}
