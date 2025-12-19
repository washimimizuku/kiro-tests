# Rust Calculator - Learn Lexers and Parsers

A complete implementation of a calculator that demonstrates how to build a **lexer** (tokenizer) and **parser** for a simple programming language. Perfect for learning compiler and interpreter fundamentals!

## 🚀 Features

- **Arithmetic Operations**: `+`, `-`, `*`, `/`, `%`, `^` with correct precedence
- **Variables**: `x = 5; y = x + 2`
- **Parentheses**: `(2 + 3) * 4`
- **Unary Minus**: `-5`, `abs(-3)`, `sin(-1)`
- **Multiple Statements**: `x = 5; y = x + 2; x * y`
- **Proper Precedence**: `2 + 3 * 4 = 14` (not 20)
- **Right Associativity**: `2^3^2 = 512` (not 64)

### 🧮 Mathematical Functions

- **Trigonometric**: `sin(x)`, `cos(x)`, `tan(x)`, `asin(x)`, `acos(x)`, `atan(x)`
- **Mathematical**: `sqrt(x)`, `abs(x)`, `floor(x)`, `ceil(x)`, `round(x)`
- **Constants**: `pi()`, `e()`
- **Multi-argument**: `min(x,y)`, `max(x,y)`, `pow(x,y)`, `atan2(y,x)`

## 🎯 Learning Goals

This project teaches:
- **Lexical Analysis**: Converting text into tokens
- **Parsing**: Building program structure from tokens
- **Recursive Descent**: A popular parsing technique
- **Operator Precedence**: How `2 + 3 * 4` becomes `2 + (3 * 4)`
- **Symbol Tables**: Storing and looking up variables
- **Language Design**: Making syntax decisions

## 🏃 Quick Start

### Three Ways to Use the Calculator:

#### 1. Interactive CLI Mode (Recommended)
```bash
cargo run -- --interactive
# or
cargo run -- -i
```

This starts an interactive REPL where you can:
- Enter expressions and see results immediately
- Variables persist between expressions
- Use command history (up/down arrows)
- Type `help` for help, `vars` to see variables, `quit` to exit

```
calc> 2 + 3 * 4
= 14
calc> x = 5
= 5
calc> y = x + 2
= 7
calc> sin(pi() / 2)
= 1
calc> vars
Current variables:
  x = 5
  y = 7
```

#### 2. Single Expression Evaluation
```bash
cargo run -- --eval "2 + 3 * 4"
# Output: 14

cargo run -- -e "sin(pi() / 2)"
# Output: 1
```

#### 3. Demonstration Mode (Default)
```bash
cargo run
```

You'll see output demonstrating various expressions:

```
=== RUST CALCULATOR DEMONSTRATION ===
Evaluating: 2 + 3
Result: 5

Evaluating: sin(pi() / 2)
Result: 1

Evaluating: sqrt(16)
Result: 4

Evaluating: min(5, 3)
Result: 3

Evaluating: x = pi(); cos(x)
Result: -1
```

## 📚 How It Works

### 1. Lexer (Tokenizer)
Converts text into tokens:
```
"x = 2 + 3" → [Identifier("x"), Assign, Number(2), Plus, Number(3)]
```

### 2. Parser (Recursive Descent)
Uses grammar rules to understand structure:
```
expression → term (('+' | '-') term)*
term       → power (('*' | '/' | '%') power)*
power      → factor ('^' factor)*
factor     → NUMBER | IDENTIFIER | FUNCTION '(' args ')' | '-' factor | '(' expression ')'
args       → expression (',' expression)*  // For multi-argument functions
```

### 3. Precedence Hierarchy
```
Highest:  ( )           Parentheses
          ^             Power (right associative)
          * / %         Multiply, Divide, Modulo
Lowest:   + -           Add, Subtract
```

## 🧪 Try These Examples

```rust
// Basic arithmetic
2 + 3 * 4        // = 14 (not 20, * has higher precedence)
(2 + 3) * 4      // = 20 (parentheses override precedence)

// Power operations
2 ^ 3            // = 8
2 ^ 3 ^ 2        // = 512 (right associative: 2^(3^2))

// Trigonometric functions
sin(pi() / 2)    // = 1 (sin of π/2)
cos(pi())        // = -1 (cos of π)
atan2(1, 1)      // = π/4 ≈ 0.7854

// Mathematical functions
sqrt(16)         // = 4
abs(-5)          // = 5
floor(3.7)       // = 3
ceil(3.2)        // = 4
min(5, 3)        // = 3
max(5, 3)        // = 5

// Complex expressions
sin(pi() / 4) * sqrt(2)     // ≈ 1.0
min(abs(-7), sqrt(25))      // = 5
pow(sin(pi()/2), 2)         // = 1

// Variables with functions
x = pi(); y = sin(x / 2)    // y = 1
radius = 5; area = pi() * radius ^ 2  // = 78.54
```

## 🏗️ Architecture

```
Input: "x = 2 + 3"
       ↓
   [Lexer] → Tokens: [Identifier("x"), Assign, Number(2), Plus, Number(3)]
       ↓
   [Parser] → Parse tree and evaluation
       ↓
   Output: 5.0 (and x is stored as 5.0)
```

## 📖 Code Structure

- **`Token` enum**: Defines all possible tokens (numbers, operators, functions, etc.)
- **`Lexer` struct**: Converts text to tokens with function name recognition
- **`Parser` struct**: Parses tokens using recursive descent
- **Grammar methods**: `expr()`, `term()`, `power()`, `factor()` with precedence
- **Function tables**: 
  - `call_function()` - Single-argument functions
  - `call_constant()` - Zero-argument functions (constants)
  - `call_two_arg_function()` - Multi-argument functions
- **Symbol table**: `HashMap` storing variable values

## 🎓 Educational Features

The code is heavily commented with:
- **Concept explanations**: What is a lexer? What is recursive descent?
- **Grammar rules**: Formal definitions for each parsing method
- **Examples**: Input/output examples for each function
- **Design decisions**: Why certain choices were made
- **Rust patterns**: Explanation of Rust-specific code

## 🔧 Extending the Calculator

Want to add more features? Try:

### Easy Additions
- ✅ **Unary minus**: `-5` or `-(2 + 3)` - **IMPLEMENTED**
- ✅ **Built-in functions**: `sin(3.14)`, `sqrt(16)` - **IMPLEMENTED**
- **Comparison operators**: `==`, `!=`, `<`, `>`, `<=`, `>=`
- **More math functions**: `log(x)`, `ln(x)`, `exp(x)`

### Medium Complexity
- **Boolean logic**: `&&`, `||`, `!`
- **Conditional expressions**: `x > 5 ? 10 : 20`
- **Block statements**: `{ x = 5; y = x + 2 }`
- **Variable-argument functions**: `sum(1, 2, 3, 4)`

### Advanced Features
- **Control flow**: `if`, `while` loops
- **User-defined functions**: `def square(x) { x * x }`
- **Arrays**: `[1, 2, 3, 4]`
- **String support**: `"hello " + "world"`

## 🤝 Contributing

This is a learning project! Feel free to:
- Add more operators or features
- Improve error messages
- Add more test cases
- Enhance the documentation

## 📚 Further Reading

- **"Crafting Interpreters"** by Robert Nystrom - Excellent hands-on book
- **"Writing An Interpreter In Go"** - Step-by-step approach
- **Dragon Book** - Classic compiler theory (more advanced)

## 🏷️ Tags

`#rust` `#compiler` `#interpreter` `#lexer` `#parser` `#recursive-descent` `#learning` `#calculator` `#programming-language`

---

**Happy parsing!** 🎉 This project demonstrates that building a programming language isn't magic - it's just careful application of well-understood techniques.