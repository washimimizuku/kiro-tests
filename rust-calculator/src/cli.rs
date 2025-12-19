// ============================================================================
// CLI MODULE - Interactive Calculator Interface
// ============================================================================
// This module provides a command-line interface for the calculator, allowing
// users to interactively enter expressions and see results.

use crate::{Lexer, Parser};
use rustyline::error::ReadlineError;
use rustyline::DefaultEditor;
use std::collections::HashMap;

/// Interactive CLI calculator
/// Maintains state between expressions (variables persist)
pub struct CalculatorCLI {
    editor: DefaultEditor,
    variables: HashMap<String, f64>,
}

impl CalculatorCLI {
    /// Create a new CLI calculator instance
    pub fn new() -> rustyline::Result<Self> {
        let editor = DefaultEditor::new()?;
        Ok(CalculatorCLI {
            editor,
            variables: HashMap::new(),
        })
    }

    /// Start the interactive REPL (Read-Eval-Print Loop)
    pub fn run(&mut self) -> rustyline::Result<()> {
        println!("🧮 Rust Calculator - Interactive Mode");
        println!("Type expressions like: 2 + 3, sin(pi()/2), x = 5; y = x + 2");
        println!("Type 'help' for help, 'vars' to see variables, 'quit' to exit");
        println!();

        loop {
            let readline = self.editor.readline("calc> ");
            match readline {
                Ok(line) => {
                    let line = line.trim();
                    
                    // Handle special commands
                    match line {
                        "" => continue, // Empty line
                        "quit" | "exit" | "q" => {
                            println!("Goodbye! 👋");
                            break;
                        }
                        "help" | "h" => {
                            self.show_help();
                            continue;
                        }
                        "vars" | "variables" => {
                            self.show_variables();
                            continue;
                        }
                        "clear" => {
                            self.variables.clear();
                            println!("Variables cleared.");
                            continue;
                        }
                        _ => {}
                    }

                    // Add to history
                    self.editor.add_history_entry(line)?;

                    // Evaluate expression
                    match self.evaluate_expression(line) {
                        Ok(result) => {
                            println!("= {}", result);
                        }
                        Err(error) => {
                            println!("Error: {}", error);
                        }
                    }
                }
                Err(ReadlineError::Interrupted) => {
                    println!("CTRL-C");
                    break;
                }
                Err(ReadlineError::Eof) => {
                    println!("CTRL-D");
                    break;
                }
                Err(err) => {
                    println!("Error: {:?}", err);
                    break;
                }
            }
        }

        Ok(())
    }

    /// Evaluate a single expression and update variables
    fn evaluate_expression(&mut self, input: &str) -> std::result::Result<f64, String> {
        // Create lexer and parser
        let lexer = Lexer::new(input);
        let mut parser = Parser::new(lexer);
        
        // Transfer existing variables to parser
        parser.set_variables(self.variables.clone());

        // Parse and evaluate
        let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            parser.parse()
        }));

        match result {
            Ok(value) => {
                // Update our variables with any new assignments
                self.variables = parser.get_variables();
                Ok(value)
            }
            Err(_) => Err("Invalid expression".to_string()),
        }
    }

    /// Show help information
    fn show_help(&self) {
        println!("🧮 Calculator Help");
        println!();
        println!("Arithmetic:");
        println!("  2 + 3 * 4        Basic arithmetic with precedence");
        println!("  2 ^ 3            Exponentiation (right associative)");
        println!("  10 % 3           Modulo (remainder)");
        println!("  -5               Unary minus");
        println!();
        println!("Variables:");
        println!("  x = 5            Assign value to variable");
        println!("  y = x + 2        Use variables in expressions");
        println!("  x = 5; y = x * 2 Multiple statements");
        println!();
        println!("Functions:");
        println!("  sin(pi()/2)      Trigonometric: sin, cos, tan, asin, acos, atan");
        println!("  sqrt(16)         Mathematical: sqrt, abs, floor, ceil, round");
        println!("  ln(e()), exp(1)  Logarithmic/exponential: ln, log10, log2, exp");
        println!("  pi(), e()        Constants");
        println!("  min(5, 3)        Multi-argument: min, max, pow, atan2");
        println!();
        println!("Commands:");
        println!("  help             Show this help");
        println!("  vars             Show current variables");
        println!("  clear            Clear all variables");
        println!("  quit             Exit calculator");
        println!();
    }

    /// Show current variables
    fn show_variables(&self) {
        if self.variables.is_empty() {
            println!("No variables defined.");
        } else {
            println!("Current variables:");
            let mut vars: Vec<_> = self.variables.iter().collect();
            vars.sort_by_key(|(name, _)| *name);
            for (name, value) in vars {
                println!("  {} = {}", name, value);
            }
        }
    }
}