# Rust Calculator - Learn Lexers and Parsers

A complete implementation of a calculator that demonstrates how to build a **lexer** (tokenizer) and **parser** for a simple programming language. Perfect for learning compiler and interpreter fundamentals!

## 🚀 Features

- **Arithmetic Operations**: `+`, `-`, `*`, `/`, `%`, `^` with correct precedence
- **Variables**: `x = 5; y = x + 2`
- **Parentheses**: `(2 + 3) * 4`
- **Multiple Statements**: `x = 5; y = x + 2; x * y`
- **Proper Precedence**: `2 + 3 * 4 = 14` (not 20)
- **Right Associativity**: `2^3^2 = 512` (not 64)

## 🎯 Learning Goals

This project teaches:
- **Lexical Analysis**: Converting text into tokens
- **Parsing**: Building program structure from tokens
- **Recursive Descent**: A popular parsing technique
- **Operator Precedence**: How `2 + 3 * 4` becomes `2 + (3 * 4)`
- **Symbol Tables**: Storing and looking up variables
- **Language Design**: Making syntax decisions

## 🏃 Quick Start

```bash
# Clone and run
git clone <your-repo-url>
cd rust-calculator
cargo run
```

You'll see output demonstrating various expressions:

```
=== RUST CALCULATOR DEMONSTRATION ===
Evaluating: 2 + 3
Result: 5

Evaluating: 2 ^ 3 ^ 2
Result: 512

Evaluating: x = 2; y = 3; x ^ y
Result: 8
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
factor     → NUMBER | IDENTIFIER | '(' expression ')'
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

// Variables
x = 5            // Assigns 5 to x
y = x + 2        // Uses x in expression
x * y            // = 35

// Multiple statements
x = 2; y = 3; x ^ y  // = 8
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

- **`Token` enum**: Defines all possible tokens
- **`Lexer` struct**: Converts text to tokens
- **`Parser` struct**: Parses tokens using recursive descent
- **Grammar methods**: `expr()`, `term()`, `power()`, `factor()`
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
- **Unary minus**: `-5` or `-(2 + 3)`
- **Comparison operators**: `==`, `!=`, `<`, `>`
- **Built-in functions**: `sin(3.14)`, `sqrt(16)`

### Medium Complexity
- **Boolean logic**: `&&`, `||`, `!`
- **Conditional expressions**: `x > 5 ? 10 : 20`
- **Block statements**: `{ x = 5; y = x + 2 }`

### Advanced Features
- **Control flow**: `if`, `while` loops
- **User-defined functions**: `def square(x) { x * x }`
- **Arrays**: `[1, 2, 3, 4]`

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