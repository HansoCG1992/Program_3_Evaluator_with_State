# CS 441 - Program 3: Expression Evaluator with State

## Implementation Guide

### Overview

This project implements a functional expression evaluator with stateful variable management using Racket. The implementation converts the original `Maybe`-based error handling to an `Either`/`Result` type system and adds comprehensive variable operations.

---

## Table of Contents

1. [Conversion from Maybe to Either](#conversion-from-maybe-to-either)
2. [State Management Architecture](#state-management-architecture)
3. [Expression Grammar](#expression-grammar)
4. [Implementation Details](#implementation-details)
5. [REPL Interface](#repl-interface)
6. [Testing Strategy](#testing-strategy)

---

## Conversion from Maybe to Either

### Original Maybe System

The starting code used Racket's `data/maybe` library:

```racket
(require data/maybe)

;; Returns either:
;; - (just value)  ; success
;; - #<nothing>    ; failure (no error message)

(define (safe-div x y)
  (if (= y 0)
      nothing
      (just (/ x y))))
```

**Limitations:**
- No error messages - just "nothing" on failure
- No context about what went wrong
- Harder to debug and provide user feedback

### New Either/Result System

We implemented a custom `Either` type (also called `Result`):

```racket
;; Returns either:
;; - (success value)  ; success with value
;; - (failure message) ; failure with descriptive error message

(define (success value)
  (list 'success value))

(define (failure message)
  (list 'failure message))
```

**Benefits:**
- Descriptive error messages
- Better user feedback
- Easier debugging
- Functional composition of results

### Key Functions

```racket
;; Type predicates
(define (success? result)
  (and (list? result)
       (not (null? result))
       (equal? (first result) 'success)))

(define (failure? result)
  (and (list? result)
       (not (null? result))
       (equal? (first result) 'failure)))

;; Extract values with defaults
(define (from-success default result)
  (if (success? result)
      (second result)
      default))

(define (from-failure default result)
  (if (failure? result)
      (second result)
      default))
```

### Conversion Example

**Before (Maybe):**
```racket
(define (eval expr)
  (if (nothing? (eval (second expr)))
      nothing
      (just (+ 1 (from-just 0 (eval (second expr)))))))
```

**After (Either):**
```racket
(define (eval-expr expr state)
  (let ([result (eval-expr (second expr) state)])
    (if (failure? (car result))
        result  ; propagate failure with message
        (cons (success (+ 1 (from-success 0 (car result))))
              (cdr result)))))
```

---

## State Management Architecture

### Data Structure

State is implemented as an **immutable association list**:

```racket
;; State structure: list of (id . value) pairs
;; Example: '((x . 10) (y . undefined) (z . 25))

(define empty-state '())
(define UNDEFINED 'undefined)
```

### Why Association List?

1. **Immutability**: Functional programming paradigm
2. **Simplicity**: Easy to implement and understand
3. **Efficiency**: Good for small state sizes (typical for this use case)

**Alternative considered:** Hash tables (would be better for large states)

### State Operations

#### 1. Check Existence
```racket
(define (id-exists? id state)
  (assoc id state))  ; Returns binding or #f
```

#### 2. Get Value
```racket
(define (get-id-value id state)
  (let ([binding (assoc id state)])
    (if binding
        (cdr binding)
        #f)))
```

#### 3. Add Identifier
```racket
(define (add-id id value state)
  (if (id-exists? id state)
      #f  ; Already exists - return false
      (cons (cons id value) state)))  ; Return new state
```

#### 4. Update Identifier
```racket
(define (update-id id value state)
  (cond
    [(null? state) #f]
    [(equal? (caar state) id)
     (cons (cons id value) (cdr state))]  ; Replace first matching
    [else
     (let ([rest (update-id id value (cdr state))])
       (if rest
           (cons (car state) rest)
           #f))]))
```

#### 5. Remove Identifier
```racket
(define (remove-id id state)
  (cond
    [(null? state) #f]
    [(equal? (caar state) id) (cdr state)]  ; Skip this binding
    [else
     (let ([rest (remove-id id (cdr state))])
       (if rest
           (cons (car state) rest)
           #f))]))
```

### Immutability Principle

All state operations return **new states** without modifying the original:

```racket
(define state1 '((x . 10)))
(define state2 (add-id 'y 20 state1))

;; state1 is unchanged: '((x . 10))
;; state2 is new:       '((y . 20) (x . 10))
```

---

## Expression Grammar

### Full Grammar

```
<expr> ::= <num-expr>
         | <arith-expr>
         | <id-expr>
         | <define-expr>
         | <assign-expr>
         | <remove-expr>

<num-expr>    ::= (num <number>)
<arith-expr>  ::= (<op> <expr> <expr>)  where <op> ∈ {add, sub, mult, div}
<id-expr>     ::= (id <identifier>)
<define-expr> ::= (define <identifier>)
                | (define <identifier> <expr>)
<assign-expr> ::= (assign <identifier> <expr>)
<remove-expr> ::= (remove <identifier>)

<identifier>  ::= <letter> (<letter> | <digit> | '-' | '_')*
```

### Identifier Validation

```racket
(define (valid-id? sym)
  (and (symbol? sym)
       (let ([str (symbol->string sym)])
         (and (> (string-length str) 0)
              (char-alphabetic? (string-ref str 0))
              (andmap (λ (c) (or (char-alphabetic? c)
                                  (char-numeric? c)
                                  (equal? c #\-)
                                  (equal? c #\_)))
                      (string->list str))))))
```

**Valid:** `x`, `my_var`, `my-var-2`, `MyVar_123`
**Invalid:** `123var`, `my@var`, `_start`

---

## Implementation Details

### Evaluator Signature

```racket
;; eval-expr: expression state -> (result . state)
;;
;; Takes an expression and current state
;; Returns a pair: (result . new-state)
;; - result is either (success value) or (failure message)
;; - new-state is the updated state (or original on failure)
```

### Key Design Decisions

#### 1. Error Propagation

When an error occurs, it propagates up the call chain:

```racket
(let* ([left-result (eval-expr (second expr) state)]
       [left-val (car left-result)])
  (if (failure? left-val)
      left-result  ; Propagate failure immediately
      ;; ... continue with right operand
```

#### 2. State Preservation on Failure

Failed operations don't modify state:

```racket
(define (eval-expr expr state)
  (cond
    [(equal? (first expr) 'define)
     (let ([result (eval-expr (value-expr) state)])
       (if (failure? (car result))
           (cons (car result) state)  ; Original state!
           ;; ... create variable in new state
```

#### 3. Immutability Enforcement

Variables cannot be reassigned once they have a value:

```racket
[(equal? (first expr) 'assign)
 (if (not (equal? current-value UNDEFINED))
     (cons (failure "identifier already has a value (data is immutable)") state)
     ;; ... perform assignment
```

### Operation Implementations

#### NUM - Numeric Literal
```racket
[(equal? (first expr) 'num)
 (if (and (= (length expr) 2) (number? (second expr)))
     (cons (success (second expr)) state)
     (cons (failure "num: invalid syntax") state))]
```

#### ADD/SUB/MULT/DIV - Arithmetic
```racket
[(member (first expr) '(add sub mult div))
 (let* ([left-result (eval-expr (second expr) state)]
        [right-result (eval-expr (third expr) state)])
   ;; Check for failures, then compute
   (cond
     [(equal? op 'add) (success (+ x y))]
     [(equal? op 'div) (safe-div x y)]
     ;; ... etc.
```

#### ID - Variable Reference
```racket
[(equal? (first expr) 'id)
 (let ([value (get-id-value id-name state)])
   (cond
     [(not value) (failure "identifier not defined")]
     [(equal? value UNDEFINED) (failure "identifier is undefined")]
     [else (success value)]))]
```

#### DEFINE - Create Variable
```racket
[(equal? (first expr) 'define)
 (if (id-exists? id-name state)
     (failure "identifier already defined")
     (if (= (length expr) 2)
         ;; No initial value
         (cons (success id-name) (add-id id-name UNDEFINED state))
         ;; With initial value
         (let ([value-result (eval-expr (third expr) state)])
           (if (failure? (car value-result))
               (cons (car value-result) state)
               (cons (success id-name)
                     (add-id id-name (from-success 0 (car value-result)) state))))))]
```

#### ASSIGN - Assign to Undefined Variable
```racket
[(equal? (first expr) 'assign)
 (cond
   [(not current-value) (failure "identifier not defined")]
   [(not (equal? current-value UNDEFINED))
    (failure "identifier already has a value (data is immutable)")]
   [else
    (let ([value-result (eval-expr value-expr state)])
      (if (failure? (car value-result))
          (cons (car value-result) state)
          (cons (success id-name)
                (update-id id-name (from-success 0 (car value-result)) state))))])]
```

#### REMOVE - Delete Variable
```racket
[(equal? (first expr) 'remove)
 (if (not (id-exists? id-name state))
     (failure "identifier not defined")
     (cons (success id-name) (remove-id id-name state)))]
```

---

## REPL Interface

### Main Loop

```racket
(define (repl [state empty-state])
  (display "\n> ")
  (flush-output)
  (let ([input (read)])
    (cond
      [(eof-object? input) (exit)]
      [(equal? input 'quit) (exit)]
      [(equal? input 'state) (print-state state) (repl state)]
      [(equal? input 'help) (print-help) (repl state)]
      [else
       (let* ([result-pair (eval-expr input state)]
              [result (car result-pair)]
              [new-state (cdr result-pair)])
         (print-result result)
         (when (failure? result)
           (displayln "  State unchanged"))
         (repl new-state))])))
```

### Special Commands

- `state` - Display current variable bindings
- `help` - Show available commands
- `quit`, `exit`, `q` - Exit REPL
- Ctrl+D (EOF) - Exit REPL

### Output Format

```
> (define x (num 10))
  Success: x
  State:
    x = 10

> (add (id x) (num 5))
  Success: 15

> (id nonexistent)
  Error: id nonexistent: identifier not defined
  State unchanged
```

---

## Testing Strategy

### Unit Tests

The implementation includes comprehensive tests:

1. **Basic Arithmetic** (Tests 1-4)
   - Simple operations
   - Nested expressions
   - Division by zero

2. **State Management** (Tests 5-11)
   - Define undefined variable
   - Assign to undefined variable
   - Define with initial value
   - Remove variable
   - Use variables in expressions

3. **Edge Cases** (Tests 12-16)
   - Duplicate definitions
   - Invalid assignments
   - Immutability violations
   - Invalid identifiers

### Test Coverage

```racket
;; Run all tests automatically on startup:
(displayln "=== Running Initial Tests ===")

;; Test basic arithmetic
(eval-expr '(num 5) empty-state)
(eval-expr '(add (num 5) (mult (num 2) (num 3))) empty-state)

;; Test state operations
(let* ([r1 (eval-expr '(define a) empty-state)]
       [s1 (cdr r1)]
       [r2 (eval-expr '(assign a (num 10)) s1)]
       [s2 (cdr r2)])
  (eval-expr '(add (id a) (num 5)) s2))
```

### Manual Testing via REPL

The REPL allows interactive testing of all features:

```
$ racket evaluator.rkt
> (define x (num 5))
> (define y (add (id x) (num 3)))
> (mult (id x) (id y))
> state
> quit
```

---

## Key Implementation Insights

### 1. Functional State Threading

State is threaded through the evaluation:

```racket
;; Pattern: receive state, return (result . new-state)
(define (eval-expr expr state)
  ...
  (cons result new-state))
```

### 2. Error Handling Philosophy

- **Fail fast**: Errors propagate immediately
- **Preserve state**: Failed operations don't corrupt state
- **Descriptive messages**: All errors include context

### 3. Immutability Benefits

- **No side effects**: Pure functions
- **Easy testing**: Predictable behavior
- **Thread-safe**: No race conditions (if extended to concurrent version)
- **Time travel**: Can maintain state history

### 4. Type Safety

While Racket is dynamically typed, we maintain invariants:

```racket
;; Invariant: State is always a list of (symbol . (number | 'undefined))
;; Invariant: Results are always (success value) or (failure message)
```

---

## Extension Ideas

1. **Add more types**: strings, booleans, lists
2. **Add control flow**: if/else expressions
3. **Add functions**: lambda expressions, function calls
4. **Add let bindings**: scoped variables
5. **Add persistence**: save/load state from file
6. **Add type checking**: static type analysis
7. **Add debugging**: step-through execution

---

## Conclusion

This implementation successfully:

✅ Converts from Maybe to Either/Result
✅ Implements stateful variable management
✅ Maintains functional programming principles
✅ Provides comprehensive error handling
✅ Includes thorough testing
✅ Offers interactive REPL interface

The code is production-quality, well-documented, and ready for demonstration and further extension.
