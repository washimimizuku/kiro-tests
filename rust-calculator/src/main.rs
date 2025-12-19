// ============================================================================
// RUST CALCULATOR - A LEARNING PROJECT FOR LEXERS AND PARSERS
// ============================================================================
//
// This is a complete implementation of a calculator that demonstrates how to
// build a lexer (tokenizer) and parser for a simple programming language.
//
// FEATURES:
// - Arithmetic operators: + - * / % ^ (with correct precedence)
// - Variables: x = 5; y = x + 2
// - Parentheses for grouping: (2 + 3) * 4
// - Multiple statements: x = 5; y = x + 2; x * y
//
// ARCHITECTURE:
// 1. LEXER: Converts text "2 + 3" into tokens [Number(2), Plus, Number(3)]
// 2. PARSER: Uses recursive descent to build understanding and evaluate
//
// PRECEDENCE (highest to lowest):
// - Parentheses: ()
// - Power: ^ (right associative)
// - Multiply/Divide/Modulo: * / %
// - Add/Subtract: + -
//
// This is an excellent starting point for learning compiler/interpreter design!
//
// ============================================================================
// TOKEN DEFINITION
// ============================================================================
// Tokens are the "words" of our programming language. The lexer breaks down
// source code into these atomic units that the parser can understand.

#[derive(Debug, Clone, PartialEq)]
pub enum Token {
    // Literals and identifiers
    Number(f64),         // Numbers like 3.14, 42, -5.0
    Identifier(String),  // Variable names like "x", "foo", "my_var"
    
    // Arithmetic operators (in order of precedence, lowest to highest)
    Plus,                // + addition
    Minus,               // - subtraction  
    Multiply,            // * multiplication
    Divide,              // / division
    Modulo,              // % remainder (e.g., 10 % 3 = 1)
    Power,               // ^ exponentiation (e.g., 2^3 = 8)
    
    // Grouping and structure
    LeftParen,           // ( for grouping expressions
    RightParen,          // ) for grouping expressions
    Comma,               // , for function arguments (future use)
    Assign,              // = for variable assignment
    Semicolon,           // ; to separate statements
    
    // Functions
    Function(String),    // Function names like "sin", "cos", "tan"
    
    // Special
    EOF,                 // End of file/input marker
}

// ============================================================================
// LEXER (TOKENIZER)
// ============================================================================
// The lexer's job is to take raw text like "x = 2 + 3" and break it into
// tokens like [Identifier("x"), Assign, Number(2.0), Plus, Number(3.0)]
//
// Think of it like reading a sentence and identifying: noun, verb, adjective, etc.

#[derive(Clone)]
pub struct Lexer {
    input: Vec<char>,           // The source code as individual characters
    position: usize,            // Current position in the input
    current_char: Option<char>, // The character we're currently looking at
}

impl Lexer {
    /// Create a new lexer from input string
    /// Example: Lexer::new("2 + 3") sets up lexer to tokenize "2 + 3"
    pub fn new(input: &str) -> Self {
        let chars: Vec<char> = input.chars().collect();
        let current_char = chars.get(0).copied(); // Start at first character
        
        Lexer {
            input: chars,
            position: 0,
            current_char,
        }
    }

    /// Move to the next character in the input
    /// Like moving a cursor forward when reading text
    fn advance(&mut self) {
        self.position += 1;
        self.current_char = self.input.get(self.position).copied();
    }

    /// Skip over whitespace characters (spaces, tabs, newlines)
    /// We ignore whitespace since it doesn't affect meaning in our language
    fn skip_whitespace(&mut self) {
        while let Some(ch) = self.current_char {
            if ch.is_whitespace() {
                self.advance();
            } else {
                break;
            }
        }
    }

    /// Read a complete number (including decimals)
    /// Examples: "42" -> 42.0, "3.14" -> 3.14, "0.5" -> 0.5
    fn read_number(&mut self) -> f64 {
        let mut number_str = String::new();
        
        // Keep reading digits and decimal points
        while let Some(ch) = self.current_char {
            if ch.is_ascii_digit() || ch == '.' {
                number_str.push(ch);
                self.advance();
            } else {
                break; // Stop when we hit a non-digit, non-decimal character
            }
        }
        
        // Convert string to number, default to 0.0 if parsing fails
        number_str.parse().unwrap_or(0.0)
    }

    /// Read a complete identifier (variable name)
    /// Examples: "x" -> "x", "my_var" -> "my_var", "foo123" -> "foo123"
    /// Rules: Must start with letter or underscore, then can contain letters, digits, underscores
    fn read_identifier(&mut self) -> String {
        let mut identifier = String::new();
        
        // Keep reading valid identifier characters
        while let Some(ch) = self.current_char {
            if ch.is_ascii_alphabetic() || ch.is_ascii_digit() || ch == '_' {
                identifier.push(ch);
                self.advance();
            } else {
                break; // Stop when we hit an invalid identifier character
            }
        }
        
        identifier
    }

    /// Get the next token from the input
    /// This is the main method that identifies what kind of token we're looking at
    /// and returns the appropriate Token enum variant
    pub fn next_token(&mut self) -> Token {
        // Keep processing characters until we find a token or reach end of input
        while let Some(ch) = self.current_char {
            match ch {
                // Whitespace: skip it and continue
                ' ' | '\t' | '\n' => {
                    self.skip_whitespace();
                    continue;
                }
                
                // Single-character operators: recognize and advance
                '+' => {
                    self.advance();
                    return Token::Plus;
                }
                '-' => {
                    self.advance();
                    return Token::Minus;
                }
                '*' => {
                    self.advance();
                    return Token::Multiply;
                }
                '/' => {
                    self.advance();
                    return Token::Divide;
                }
                '^' => {
                    self.advance();
                    return Token::Power;
                }
                '%' => {
                    self.advance();
                    return Token::Modulo;
                }
                '(' => {
                    self.advance();
                    return Token::LeftParen;
                }
                ')' => {
                    self.advance();
                    return Token::RightParen;
                }
                '=' => {
                    self.advance();
                    return Token::Assign;
                }
                ';' => {
                    self.advance();
                    return Token::Semicolon;
                }
                ',' => {
                    self.advance();
                    return Token::Comma;
                }
                
                // Multi-character tokens: use helper methods
                _ if ch.is_ascii_digit() => {
                    // Found a digit, read the complete number
                    let number = self.read_number();
                    return Token::Number(number);
                }
                _ if ch.is_ascii_alphabetic() || ch == '_' => {
                    // Found a letter or underscore, read the complete identifier
                    let identifier = self.read_identifier();
                    
                    // Check if this is a known function name
                    return match identifier.as_str() {
                        // Trigonometric functions
                        "sin" | "cos" | "tan" | "asin" | "acos" | "atan" |
                        // Mathematical functions
                        "sqrt" | "abs" | "floor" | "ceil" | "round" |
                        // Mathematical constants (zero-argument functions)
                        "pi" | "e" => Token::Function(identifier),
                        _ => Token::Identifier(identifier),
                    };
                }
                
                // Unknown character: this is an error
                _ => {
                    panic!("Unexpected character: {}", ch);
                }
            }
        }
        
        // No more characters to process
        Token::EOF
    }
}

use std::collections::HashMap;

// ============================================================================
// PARSER (RECURSIVE DESCENT)
// ============================================================================
// The parser takes tokens from the lexer and builds an understanding of the
// program structure. It uses "recursive descent" - each grammar rule becomes
// a method that calls other methods.
//
// Our grammar (in order of precedence, lowest to highest):
//   program    → statement (';' statement)*
//   statement  → assignment | expression
//   assignment → IDENTIFIER '=' expression
//   expression → term (('+' | '-') term)*
//   term       → power (('*' | '/' | '%') power)*
//   power      → factor ('^' factor)*
//   factor     → NUMBER | IDENTIFIER | '(' expression ')'

pub struct Parser {
    lexer: Lexer,                    // Source of tokens
    current_token: Token,            // The token we're currently looking at
    variables: HashMap<String, f64>, // Storage for variable values (symbol table)
}

impl Parser {
    /// Create a new parser with the given lexer
    /// Gets the first token to start parsing
    pub fn new(mut lexer: Lexer) -> Self {
        let current_token = lexer.next_token(); // Prime the parser with first token
        Parser {
            lexer,
            current_token,
            variables: HashMap::new(), // Start with no variables defined
        }
    }

    /// "Eat" a token - verify it's what we expect, then move to next token
    /// This is a common parser pattern for consuming expected tokens
    /// 
    /// Example: if we expect a '+' and see a '+', advance to next token
    ///          if we expect a '+' but see a '*', panic with error
    fn eat(&mut self, expected_token: Token) {
        // Use discriminant to compare token types without comparing values
        // (e.g., Number(5.0) matches Number(0.0) for type checking)
        if std::mem::discriminant(&self.current_token) == std::mem::discriminant(&expected_token) {
            self.current_token = self.lexer.next_token();
        } else {
            panic!("Expected {:?}, got {:?}", expected_token, self.current_token);
        }
    }

    /// Call a built-in function with the given argument
    /// This is our function table - maps function names to implementations
    /// 
    /// Function categories:
    ///   - Trigonometric: sin, cos, tan (input in radians)
    ///   - Inverse trig: asin, acos, atan (output in radians)
    ///   - Mathematical: sqrt, abs, floor, ceil, round
    /// 
    /// Examples:
    ///   - call_function("sqrt", 16.0) → returns 4.0
    ///   - call_function("abs", -5.0) → returns 5.0
    ///   - call_function("floor", 3.7) → returns 3.0
    fn call_function(&self, name: &str, arg: f64) -> f64 {
        match name {
            // Basic trigonometric functions
            "sin" => arg.sin(),
            "cos" => arg.cos(),
            "tan" => arg.tan(),
            
            // Inverse trigonometric functions
            "asin" => arg.asin(),   // Returns value in [-π/2, π/2]
            "acos" => arg.acos(),   // Returns value in [0, π]
            "atan" => arg.atan(),   // Returns value in (-π/2, π/2)
            
            // Mathematical functions
            "sqrt" => arg.sqrt(),   // Square root
            "abs" => arg.abs(),     // Absolute value
            "floor" => arg.floor(), // Round down to nearest integer
            "ceil" => arg.ceil(),   // Round up to nearest integer
            "round" => arg.round(), // Round to nearest integer
            
            _ => panic!("Unknown function: {}", name),
        }
    }

    /// Call a mathematical constant (zero-argument function)
    /// These are functions that take no arguments and return constant values
    /// 
    /// Examples:
    ///   - call_constant("pi") → returns π ≈ 3.14159
    ///   - call_constant("e") → returns e ≈ 2.71828
    fn call_constant(&self, name: &str) -> f64 {
        match name {
            "pi" => std::f64::consts::PI,  // π ≈ 3.14159265359
            "e" => std::f64::consts::E,    // e ≈ 2.71828182846
            _ => panic!("Unknown constant: {}", name),
        }
    }

    /// Parse a factor: the highest precedence elements
    /// factor → NUMBER | IDENTIFIER | FUNCTION '(' expression ')' | '(' expression ')' | '-' factor
    /// 
    /// Examples:
    ///   - "42" → returns 42.0
    ///   - "-5" → returns -5.0 (unary minus)
    ///   - "x" → looks up variable x and returns its value
    ///   - "sin(3.14)" → calls sin function with 3.14 and returns result
    ///   - "(2 + 3)" → recursively parses "2 + 3" and returns 5.0
    fn factor(&mut self) -> f64 {
        let token = self.current_token.clone();
        
        match token {
            Token::Number(value) => {
                // Found a number literal
                self.eat(Token::Number(0.0)); // Consume the number token
                value
            }
            Token::Identifier(name) => {
                // Found a variable reference
                self.eat(Token::Identifier(String::new())); // Consume the identifier token
                
                // Look up the variable's value in our symbol table
                *self.variables.get(&name).unwrap_or_else(|| {
                    panic!("Undefined variable: {}", name);
                })
            }
            Token::Function(name) => {
                // Found a function call
                self.eat(Token::Function(String::new())); // Consume the function name
                self.eat(Token::LeftParen);               // Consume '('
                
                // Check if this is a zero-argument function (constant)
                let result = match name.as_str() {
                    "pi" | "e" => {
                        // Zero-argument function (constant)
                        self.call_constant(&name)
                    }
                    _ => {
                        // Regular function with one argument
                        let arg = self.expr();            // Parse the argument
                        self.call_function(&name, arg)
                    }
                };
                
                self.eat(Token::RightParen);              // Consume ')'
                result
            }
            Token::Minus => {
                // Found unary minus (negative number)
                self.eat(Token::Minus);       // Consume the '-'
                -self.factor()                // Recursively parse the factor and negate it
            }
            Token::LeftParen => {
                // Found parentheses - parse the expression inside
                self.eat(Token::LeftParen);   // Consume '('
                let result = self.expr();     // Recursively parse the expression inside
                self.eat(Token::RightParen);  // Consume ')'
                result
            }
            _ => panic!("Unexpected token in factor: {:?}", token),
        }
    }

    /// Parse power operations: exponentiation
    /// power → factor ('^' factor)*
    /// 
    /// Note: Power is RIGHT associative, meaning 2^3^2 = 2^(3^2) = 512, not (2^3)^2 = 64
    /// This is the mathematical convention for exponentiation.
    /// 
    /// Examples:
    ///   - "2 ^ 3" → returns 8.0
    ///   - "2 ^ 3 ^ 2" → returns 512.0 (2^(3^2))
    fn power(&mut self) -> f64 {
        let mut result = self.factor(); // Get the base

        // Right associative: if we see ^, recursively parse the right side
        if matches!(self.current_token, Token::Power) {
            self.eat(Token::Power);
            // Recursive call for right associativity: a^b^c = a^(b^c)
            result = result.powf(self.power());
        }

        result
    }

    /// Parse term operations: multiplication, division, modulo
    /// term → power (('*' | '/' | '%') power)*
    /// 
    /// These operators have the same precedence and are left associative.
    /// Left associative means: 10 / 2 / 5 = (10 / 2) / 5 = 1, not 10 / (2 / 5) = 25
    /// 
    /// Examples:
    ///   - "2 * 3" → returns 6.0
    ///   - "10 / 2" → returns 5.0
    ///   - "10 % 3" → returns 1.0 (remainder)
    ///   - "2 * 3 * 4" → returns 24.0 (left to right: (2*3)*4)
    fn term(&mut self) -> f64 {
        let mut result = self.power(); // Get the first operand

        // Keep processing * / % operators (left associative)
        while matches!(self.current_token, Token::Multiply | Token::Divide | Token::Modulo) {
            let token = self.current_token.clone();
            match token {
                Token::Multiply => {
                    self.eat(Token::Multiply);
                    result *= self.power(); // Get next operand and multiply
                }
                Token::Divide => {
                    self.eat(Token::Divide);
                    result /= self.power(); // Get next operand and divide
                }
                Token::Modulo => {
                    self.eat(Token::Modulo);
                    result %= self.power(); // Get next operand and take remainder
                }
                _ => break,
            }
        }

        result
    }

    /// Parse expression operations: addition and subtraction
    /// expression → term (('+' | '-') term)*
    /// 
    /// These have the lowest precedence, so they're evaluated last.
    /// Left associative: 10 - 3 - 2 = (10 - 3) - 2 = 5, not 10 - (3 - 2) = 9
    /// 
    /// Examples:
    ///   - "2 + 3" → returns 5.0
    ///   - "10 - 3" → returns 7.0
    ///   - "2 + 3 * 4" → returns 14.0 (not 20, because * has higher precedence)
    fn expr(&mut self) -> f64 {
        let mut result = self.term(); // Get the first operand

        // Keep processing + - operators (left associative)
        while matches!(self.current_token, Token::Plus | Token::Minus) {
            let token = self.current_token.clone();
            match token {
                Token::Plus => {
                    self.eat(Token::Plus);
                    result += self.term(); // Get next operand and add
                }
                Token::Minus => {
                    self.eat(Token::Minus);
                    result -= self.term(); // Get next operand and subtract
                }
                _ => break,
            }
        }

        result
    }

    /// Parse variable assignment: IDENTIFIER '=' expression
    /// assignment → IDENTIFIER '=' expression
    /// 
    /// Stores the result of the expression in the variable and returns the value.
    /// 
    /// Examples:
    ///   - "x = 5" → stores 5.0 in variable x, returns 5.0
    ///   - "y = x + 2" → evaluates x + 2, stores result in y, returns the result
    fn assignment(&mut self) -> f64 {
        if let Token::Identifier(name) = &self.current_token {
            let var_name = name.clone();           // Save the variable name
            self.eat(Token::Identifier(String::new())); // Consume identifier
            self.eat(Token::Assign);               // Consume '='
            let value = self.expr();               // Evaluate the right-hand side
            
            // Store the variable in our symbol table
            self.variables.insert(var_name, value);
            value // Return the assigned value
        } else {
            // This shouldn't happen if called correctly
            self.expr()
        }
    }

    /// Parse a statement: either an assignment or an expression
    /// statement → assignment | expression
    /// 
    /// We need to look ahead to distinguish between:
    ///   - "x = 5" (assignment)
    ///   - "x + 2" (expression using variable x)
    /// 
    /// Both start with an identifier, so we peek at the next token to decide.
    fn statement(&mut self) -> f64 {
        // Look ahead to see if this is an assignment (identifier followed by '=')
        if let Token::Identifier(_) = &self.current_token {
            // Save current parser state so we can restore it
            let saved_lexer = self.lexer.clone();
            let saved_token = self.current_token.clone();
            
            // Look ahead: consume identifier and check if next token is '='
            self.current_token = self.lexer.next_token();
            let is_assignment = matches!(self.current_token, Token::Assign);
            
            // Restore parser state (backtrack)
            self.lexer = saved_lexer;
            self.current_token = saved_token;
            
            if is_assignment {
                return self.assignment(); // Parse as assignment
            }
        }
        
        // Not an assignment, parse as regular expression
        self.expr()
    }

    /// Parse the entire program: a sequence of statements
    /// program → statement (';' statement)*
    /// 
    /// Handles multiple statements separated by semicolons.
    /// Returns the value of the last statement.
    /// 
    /// Examples:
    ///   - "5" → returns 5.0
    ///   - "x = 5; x + 2" → returns 7.0 (x gets 5, then evaluate x + 2)
    ///   - "a = 2; b = 3; a * b" → returns 6.0
    pub fn parse(&mut self) -> f64 {
        let mut result;
        
        // Parse statements separated by semicolons
        loop {
            result = self.statement(); // Parse one statement
            
            // Check if there's a semicolon (indicating more statements)
            if matches!(self.current_token, Token::Semicolon) {
                self.eat(Token::Semicolon); // Consume the ';'
                
                // If there's more input after the semicolon, continue parsing
                if !matches!(self.current_token, Token::EOF) {
                    continue;
                }
            }
            
            // No more statements to parse
            break;
        }
        
        // Return the value of the last statement
        result
    }
}

// ============================================================================
// MAIN FUNCTION - DEMONSTRATION
// ============================================================================
// This demonstrates our calculator with various test cases showing:
// - Basic arithmetic with correct operator precedence
// - Variable assignments and usage
// - Complex expressions combining multiple features

fn main() {
    let test_cases = vec![
        // Basic arithmetic - shows precedence works correctly
        "2 + 3",                      // Simple addition
        "2 * 3 + 4",                  // Multiplication before addition: (2*3)+4 = 10
        
        // Power and modulo operators
        "2 ^ 3",                      // Exponentiation: 2^3 = 8
        "10 % 3",                     // Modulo (remainder): 10 % 3 = 1
        "2 ^ 3 ^ 2",                  // Right associative: 2^(3^2) = 2^9 = 512
        "2 + 3 ^ 2",                  // Power before addition: 2 + (3^2) = 2 + 9 = 11
        "2 * 3 ^ 2",                  // Power before multiplication: 2 * (3^2) = 2 * 9 = 18
        "(2 + 3) ^ 2",                // Parentheses override precedence: (2+3)^2 = 5^2 = 25
        
        // Mixed operations showing precedence hierarchy
        "10 % 3 + 2",                 // Modulo before addition: (10%3) + 2 = 1 + 2 = 3
        "2 ^ 3 * 4",                  // Power before multiplication: (2^3) * 4 = 8 * 4 = 32
        "100 / 2 ^ 3",                // Power before division: 100 / (2^3) = 100 / 8 = 12.5
        
        // Variables with operators
        "x = 2; y = 3; x ^ y",        // Assign variables, then use: 2^3 = 8
        "a = 10; b = 3; a % b",       // Variables with modulo: 10 % 3 = 1
        "base = 2; exp = 8; base ^ exp", // More descriptive variable names: 2^8 = 256
        
        // Basic trigonometric functions
        "sin(0)",                     // sin(0) = 0
        "cos(0)",                     // cos(0) = 1
        "tan(0)",                     // tan(0) = 0
        "sin(1.5708)",                // sin(π/2) ≈ 1 (π/2 ≈ 1.5708)
        "cos(3.14159)",               // cos(π) ≈ -1
        
        // Inverse trigonometric functions
        "asin(0)",                    // asin(0) = 0
        "asin(1)",                    // asin(1) = π/2 ≈ 1.5708
        "acos(1)",                    // acos(1) = 0
        "acos(0)",                    // acos(0) = π/2 ≈ 1.5708
        "atan(0)",                    // atan(0) = 0
        "atan(1)",                    // atan(1) = π/4 ≈ 0.7854
        
        // Mathematical functions
        "sqrt(16)",                   // sqrt(16) = 4
        "sqrt(2)",                    // sqrt(2) ≈ 1.414
        "abs(-5)",                    // abs(-5) = 5
        "abs(3.7)",                   // abs(3.7) = 3.7
        "floor(3.7)",                 // floor(3.7) = 3
        "floor(-2.3)",                // floor(-2.3) = -3
        "ceil(3.2)",                  // ceil(3.2) = 4
        "ceil(-2.7)",                 // ceil(-2.7) = -2
        "round(3.4)",                 // round(3.4) = 3
        "round(3.6)",                 // round(3.6) = 4
        
        // Mathematical constants
        "pi()",                       // π ≈ 3.14159
        "e()",                        // e ≈ 2.71828
        "2 * pi()",                   // 2π ≈ 6.28318
        "sin(pi())",                  // sin(π) ≈ 0
        "cos(pi())",                  // cos(π) ≈ -1
        "sin(pi() / 2)",              // sin(π/2) ≈ 1
        
        // Functions with expressions
        "sqrt(2 ^ 4)",                // sqrt(16) = 4
        "abs(sin(-1))",               // abs(sin(-1)) = abs(-sin(1))
        "floor(sqrt(10))",            // floor(√10) = floor(3.16...) = 3
        "x = pi(); sin(x / 2)",       // Using constants with variables
    ];

    println!("=== RUST CALCULATOR DEMONSTRATION ===");
    println!("This calculator supports:");
    println!("- Variables: x = 5");
    println!("- Arithmetic: + - * / % ^");
    println!("- Trigonometric functions: sin(x), cos(x), tan(x), asin(x), acos(x), atan(x)");
    println!("- Mathematical functions: sqrt(x), abs(x), floor(x), ceil(x), round(x)");
    println!("- Mathematical constants: pi(), e()");
    println!("- Proper precedence: 2 + 3 * 4 = 14 (not 20)");
    println!("- Parentheses: (2 + 3) * 4 = 20");
    println!("- Multiple statements: x = 5; y = x + 2; x * y");
    println!();

    // Test each case
    for input in test_cases {
        println!("Evaluating: {}", input);
        
        // Create lexer and parser for this input
        let lexer = Lexer::new(input);
        let mut parser = Parser::new(lexer);
        
        // Parse and evaluate, catching any panics
        match std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            parser.parse()
        })) {
            Ok(result) => println!("Result: {}\n", result),
            Err(_) => println!("Error parsing expression\n"),
        }
    }
}
