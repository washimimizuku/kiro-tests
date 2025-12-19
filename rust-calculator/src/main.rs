#[derive(Debug, Clone, PartialEq)]
pub enum Token {
    Number(f64),
    Plus,
    Minus,
    Multiply,
    Divide,
    LeftParen,
    RightParen,
    EOF,
}

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
                '(' => {
                    self.advance();
                    return Token::LeftParen;
                }
                ')' => {
                    self.advance();
                    return Token::RightParen;
                }
                _ if ch.is_ascii_digit() => {
                    let number = self.read_number();
                    return Token::Number(number);
                }
                _ => {
                    panic!("Unexpected character: {}", ch);
                }
            }
        }
        
        Token::EOF
    }
}

pub struct Parser {
    lexer: Lexer,
    current_token: Token,
}

impl Parser {
    pub fn new(mut lexer: Lexer) -> Self {
        let current_token = lexer.next_token();
        Parser {
            lexer,
            current_token,
        }
    }

    fn eat(&mut self, expected_token: Token) {
        if std::mem::discriminant(&self.current_token) == std::mem::discriminant(&expected_token) {
            self.current_token = self.lexer.next_token();
        } else {
            panic!("Expected {:?}, got {:?}", expected_token, self.current_token);
        }
    }

    // factor: NUMBER | LPAREN expr RPAREN
    fn factor(&mut self) -> f64 {
        let token = self.current_token.clone();
        
        match token {
            Token::Number(value) => {
                self.eat(Token::Number(0.0)); // Just check it's a number
                value
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

    // term: factor ((MUL | DIV) factor)*
    fn term(&mut self) -> f64 {
        let mut result = self.factor();

        while matches!(self.current_token, Token::Multiply | Token::Divide) {
            let token = self.current_token.clone();
            match token {
                Token::Multiply => {
                    self.eat(Token::Multiply);
                    result *= self.factor();
                }
                Token::Divide => {
                    self.eat(Token::Divide);
                    result /= self.factor();
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

    pub fn parse(&mut self) -> f64 {
        self.expr()
    }
}

fn main() {
    let expressions = vec![
        "2 + 3",
        "2 + 3 * 4",
        "2 * 3 + 4",
        "(2 + 3) * 4",
        "2 + 3 * (4 - 1)",
        "10 / 2 - 3",
    ];

    for expr in expressions {
        let lexer = Lexer::new(expr);
        let mut parser = Parser::new(lexer);
        let result = parser.parse();
        
        println!("{} = {}", expr, result);
    }
}
