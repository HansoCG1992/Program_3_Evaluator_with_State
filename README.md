# CS 441 - Program 3: Expression Evaluator with State
# Created By: Cole Hanson

A functional expression evaluator with stateful variable management, implemented in Racket.

## Project Overview

This project implements an interpreter that evaluates arithmetic expressions and manages program state (variables). It demonstrates:

- **Either/Result type system** for robust error handling
- **Functional state management** using immutable data structures
- **Variable operations**: define, assign, remove, and reference
- **Interactive REPL** for expression evaluation

## Features

1. ✅ **Arithmetic Operations**: add, sub, mult, div with nested expressions
2. ✅ **Variable Management**: Define, assign, remove, and reference variables
3. ✅ **Error Handling**: Descriptive error messages using Either/Result pattern
4. ✅ **Immutable State**: Functional programming with pure functions
5. ✅ **Comprehensive Testing**: Automated tests + interactive REPL
6. ✅ **Input Validation**: Identifier naming rules enforcement

## Quick Start

### Prerequisites

- Racket (version 8.0 or later)
- Install from: https://racket-lang.org/

### Running the Evaluator

```bash
racket evaluator.rkt
```

This will:
1. Run all automated tests
2. Start the interactive REPL

### Example Usage

```racket
> (define x (num 10))
  Success: x
  State:
    x = 10

> (define y (add (id x) (num 5)))
  Success: y
  State:
    y = 15
    x = 10

> (mult (id x) (id y))
  Success: 150

> state
  State:
    y = 15
    x = 10

> quit
Goodbye!
```

## File Structure

```
Program_3_Evaluator_with_State/
├── evaluator.rkt              # Main implementation
├── IMPLEMENTATION_GUIDE.md    # Detailed technical documentation
├── USAGE_EXAMPLES.txt         # Comprehensive usage examples
├── test_examples.rkt          # Interactive test examples
└── README.md                  # This file
```

## Documentation

- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Complete technical documentation including:
  - Conversion from Maybe to Either
  - State management architecture
  - Implementation details
  - Testing strategy

- **[USAGE_EXAMPLES.txt](USAGE_EXAMPLES.txt)** - Comprehensive examples demonstrating:
  - All operations and commands
  - Error cases
  - Complex workflows
  - Edge cases

- **[test_examples.rkt](test_examples.rkt)** - Ready-to-use test sessions for the REPL

## Expression Grammar

```
Expressions:
  (num N)              - Numeric literal
  (add E1 E2)          - Addition
  (sub E1 E2)          - Subtraction
  (mult E1 E2)         - Multiplication
  (div E1 E2)          - Division
  (id NAME)            - Variable reference
  (define NAME)        - Define undefined variable
  (define NAME EXPR)   - Define and initialize variable
  (assign NAME EXPR)   - Assign to undefined variable
  (remove NAME)        - Remove variable from state

REPL Commands:
  state                - Show current state
  help                 - Show help menu
  quit/exit/q          - Exit REPL
```

## Identifier Rules

- Must start with a letter (a-z, A-Z)
- Followed by letters, digits, hyphens (-), or underscores (_)
- Examples: `x`, `my_var`, `my-var-2`, `Variable_123`

## Key Concepts

### Either/Result Type System

Instead of Racket's `Maybe` (just/nothing), we use:
- `(success value)` - Operation succeeded
- `(failure message)` - Operation failed with descriptive error

### Immutable State

- All state operations return new states
- Failed operations preserve original state
- Variables cannot be reassigned once they have values

### Functional Evaluation

```racket
;; eval-expr: expression state -> (result . state)
;; Returns a pair: (result . new-state)
```

## Testing

The evaluator includes comprehensive automated tests that run on startup:

1. Basic arithmetic operations
2. Division by zero handling
3. Variable definition and assignment
4. Variable removal
5. Error cases (duplicate definitions, invalid assignments, etc.)
6. Identifier validation
7. Complex nested expressions with variables

### Running Tests

Tests run automatically when you execute:
```bash
racket evaluator.rkt
```

## Development Notes

This implementation was developed following functional programming principles:

- **Pure functions**: No side effects
- **Immutable data**: State is never modified in place
- **Pattern matching**: Using Racket's `cond` for expression evaluation
- **Error propagation**: Failures propagate up the call chain

## Assignment Requirements

This project fulfills the CS 441 Program 3 requirements:

1. ✅ Convert from Maybe to Either/Result
2. ✅ Implement state management (variables and values)
3. ✅ Support define, assign, remove, and id operations
4. ✅ Implement REPL loop
5. ✅ Handle errors gracefully with descriptive messages
6. ✅ Maintain immutable state
7. ✅ Comprehensive testing

## Author

Cole Hanson

## License

Educational use for CS 441 course
