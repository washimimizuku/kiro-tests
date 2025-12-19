#[derive(Debug, Clone, PartialEq)]
pub enum Token {
    Number(f64),
    Identifier(String),  // Variable names like "x", "foo"
    Plus,
    Minus,
    Multiply,
    Divide,
    Power,               // ^ for exponentiation
    Modulo,              // % for remainder
    LeftParen,
    RightParen,
    Assign,              // = for assignment
    Semicolon,           // ; to separate statements
    EOF,
}

#[derive(Clone)]
pub struct Lexer {
    input: Vec<char>,
    position: usize,
    current_char: Option<char>,
}

impl Lexer {
    pub fn new(input: &str) -> Self {
        let chars: Vec<char> = input.chars().collect();
        let current_char = chars.get(0).copied();
        
        Lexer {
            input: chars,
            position: 0,
            current_char,
        }
    }

    fn advance(&mut self) {
        self.position += 1;
        self.current_char = self.input.get(self.position).copied();
    }

    fn skip_whitespace(&mut self) {
        while let Some(ch) = self.current_char {
            if ch.is_whitespace() {
                self.advance();
            } else {
                break;
            }
        }
    }

    fn read_number(&mut self) -> f64 {
        let mut number_str = String::new();
        
        while let Some(ch) = self.current_char {
            if ch.is_ascii_digit() || ch == '.' {
                number_str.push(ch);
                self.advance();
            } else {
                break;
            }
        }
        
        number_str.parse().unwrap_or(0.0)
    }

    fn read_identifier(&mut self) -> String {
        let mut identifier = String::new();
        
        // Start with letter or underscore, then allow letters, digits, underscores
        while let Some(ch) = self.current_char {
            if ch.is_ascii_alphabetic() || ch.is_ascii_digit() || ch == '_' {
                identifier.push(ch);
                self.advance();
            } else {
                break;
            }
        }
        
        identifier
    }

    pub fn next_token(&mut self) -> Token {
        while let Some(ch) = self.current_char {
            match ch {
                ' ' | '\t' | '\n' => {
                    self.skip_whitespace();
                    continue;
                }
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
                _ if ch.is_ascii_digit() => {
                    let number = self.read_number();
                    return Token::Number(number);
                }
                _ if ch.is_ascii_alphabetic() || ch == '_' => {
                    let identifier = self.read_identifier();
                    return Token::Identifier(identifier);
                }
                _ => {
                    panic!("Unexpected character: {}", ch);
                }
            }
        }
        
        Token::EOF
    }
}

use std::collections::HashMap;

pub struct Parser {
    lexer: Lexer,
    current_token: Token,
    variables: HashMap<String, f64>,  // Store variable name -> value
}

impl Parser {
    pub fn new(mut lexer: Lexer) -> Self {
        let current_token = lexer.next_token();
        Parser {
            lexer,
            current_token,
            variables: HashMap::new(),  // Initialize empty variable storage
        }
    }

    fn eat(&mut self, expected_token: Token) {
        if std::mem::discriminant(&self.current_token) == std::mem::discriminant(&expected_token) {
            self.current_token = self.lexer.next_token();
        } else {
            panic!("Expected {:?}, got {:?}", expected_token, self.current_token);
        }
    }

    // factor: NUMBER | IDENTIFIER | LPAREN expr RPAREN
    fn factor(&mut self) -> f64 {
        let token = self.current_token.clone();
        
        match token {
            Token::Number(value) => {
                self.eat(Token::Number(0.0)); // Just check it's a number
                value
            }
            Token::Identifier(name) => {
                self.eat(Token::Identifier(String::new())); // Just check it's an identifier
                // Look up variable value
                *self.variables.get(&name).unwrap_or_else(|| {
                    panic!("Undefined variable: {}", name);
                })
            }
            Token::LeftParen => {
                self.eat(Token::LeftParen);
                let result = self.expr();
                self.eat(Token::RightParen);
                result
            }
            _ => panic!("Unexpected token in factor: {:?}", token),
        }
    }

    // power: factor (^ factor)*
    fn power(&mut self) -> f64 {
        let mut result = self.factor();

        // Right associative: 2^3^2 = 2^(3^2) = 2^9 = 512
        if matches!(self.current_token, Token::Power) {
            self.eat(Token::Power);
            result = result.powf(self.power()); // Recursive for right associativity
        }

        result
    }

    // term: power ((MUL | DIV | MOD) power)*
    fn term(&mut self) -> f64 {
        let mut result = self.power();

        while matches!(self.current_token, Token::Multiply | Token::Divide | Token::Modulo) {
            let token = self.current_token.clone();
            match token {
                Token::Multiply => {
                    self.eat(Token::Multiply);
                    result *= self.power();
                }
                Token::Divide => {
                    self.eat(Token::Divide);
                    result /= self.power();
                }
                Token::Modulo => {
                    self.eat(Token::Modulo);
                    result %= self.power();
                }
                _ => break,
            }
        }

        result
    }

    // expr: term ((PLUS | MINUS) term)*
    fn expr(&mut self) -> f64 {
        let mut result = self.term();

        while matches!(self.current_token, Token::Plus | Token::Minus) {
            let token = self.current_token.clone();
            match token {
                Token::Plus => {
                    self.eat(Token::Plus);
                    result += self.term();
                }
                Token::Minus => {
                    self.eat(Token::Minus);
                    result -= self.term();
                }
                _ => break,
            }
        }

        result
    }

    // assignment: IDENTIFIER ASSIGN expr
    fn assignment(&mut self) -> f64 {
        if let Token::Identifier(name) = &self.current_token {
            let var_name = name.clone();
            self.eat(Token::Identifier(String::new()));
            self.eat(Token::Assign);
            let value = self.expr();
            
            // Store the variable
            self.variables.insert(var_name, value);
            value
        } else {
            // Not an assignment, just parse as expression
            self.expr()
        }
    }

    // statement: assignment | expr
    fn statement(&mut self) -> f64 {
        // Look ahead to see if this is an assignment
        if let Token::Identifier(_) = &self.current_token {
            // Save current state
            let saved_lexer = self.lexer.clone();
            let saved_token = self.current_token.clone();
            
            // Look ahead: consume identifier and check next token
            self.current_token = self.lexer.next_token();
            let is_assignment = matches!(self.current_token, Token::Assign);
            
            // Restore state
            self.lexer = saved_lexer;
            self.current_token = saved_token;
            
            if is_assignment {
                return self.assignment();
            }
        }
        
        // Not an assignment, parse as expression
        self.expr()
    }

    pub fn parse(&mut self) -> f64 {
        let mut result;
        
        // Parse statements separated by semicolons
        loop {
            result = self.statement();
            
            if matches!(self.current_token, Token::Semicolon) {
                self.eat(Token::Semicolon);
                
                // If there's more after semicolon, continue
                if !matches!(self.current_token, Token::EOF) {
                    continue;
                }
            }
            
            break;
        }
        
        result
    }
}

fn main() {
    let test_cases = vec![
        // Basic arithmetic
        "2 + 3",                      
        "2 * 3 + 4",                  
        
        // New operators
        "2 ^ 3",                      // Power: 2^3 = 8
        "10 % 3",                     // Modulo: 10 % 3 = 1
        "2 ^ 3 ^ 2",                  // Right associative: 2^(3^2) = 2^9 = 512
        "2 + 3 ^ 2",                  // Precedence: 2 + (3^2) = 2 + 9 = 11
        "2 * 3 ^ 2",                  // Precedence: 2 * (3^2) = 2 * 9 = 18
        "(2 + 3) ^ 2",                // Parentheses: (2+3)^2 = 5^2 = 25
        
        // Mixed operations
        "10 % 3 + 2",                 // 1 + 2 = 3
        "2 ^ 3 * 4",                  // 8 * 4 = 32
        "100 / 2 ^ 3",                // 100 / 8 = 12.5
        
        // Variables with new operators
        "x = 2; y = 3; x ^ y",        // 2^3 = 8
        "a = 10; b = 3; a % b",       // 10 % 3 = 1
        "base = 2; exp = 8; base ^ exp", // 2^8 = 256
    ];

    for input in test_cases {
        println!("\nEvaluating: {}", input);
        let lexer = Lexer::new(input);
        let mut parser = Parser::new(lexer);
        
        match std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            parser.parse()
        })) {
            Ok(result) => println!("Result: {}", result),
            Err(_) => println!("Error parsing expression"),
        }
    }
}
