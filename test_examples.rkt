#lang racket

;; ============================================================================
;; Interactive Test Examples for Expression Evaluator
;; ============================================================================
;; This file contains example expressions you can copy-paste into the REPL
;; to test the evaluator functionality.
;; ============================================================================

(displayln "
================================================================================
CS 441 - Program 3: Expression Evaluator Test Examples
================================================================================

To run the main evaluator, use:
    racket evaluator.rkt

Then copy and paste these examples into the REPL prompt.

================================================================================
EXAMPLE SESSION 1: Basic Arithmetic
================================================================================

(num 42)
(add (num 10) (num 5))
(sub (num 20) (num 8))
(mult (num 7) (num 6))
(div (num 100) (num 4))
(add (mult (num 3) (num 4)) (sub (num 20) (num 5)))
(div (num 10) (num 0))

================================================================================
EXAMPLE SESSION 2: Variable Definition and Usage
================================================================================

(define x (num 10))
(define y (num 20))
(add (id x) (id y))
(define sum (add (id x) (id y)))
(mult (id sum) (num 2))
state

================================================================================
EXAMPLE SESSION 3: Undefined Variables
================================================================================

(define a)
(id a)
(assign a (num 100))
(id a)
(define b (add (id a) (num 50)))
state

================================================================================
EXAMPLE SESSION 4: Error Handling
================================================================================

(define x (num 5))
(define x (num 10))
(define y (num 7))
(assign y (num 14))
(assign z (num 100))
(id nonexistent)
(remove nonexistent)

================================================================================
EXAMPLE SESSION 5: Complex Calculations
================================================================================

(define width (num 10))
(define height (num 5))
(define area (mult (id width) (id height)))
(define perimeter (mult (add (id width) (id height)) (num 2)))
state
(define double_area (mult (id area) (num 2)))
state

================================================================================
EXAMPLE SESSION 6: Remove and Redefine
================================================================================

(define temp (num 99))
(id temp)
(remove temp)
(id temp)
(define temp (num 100))
(id temp)
state

================================================================================
EXAMPLE SESSION 7: Identifier Validation
================================================================================

(define my_variable (num 1))
(define my-variable-2 (num 2))
(define MixedCase_ID (num 3))
(define 123invalid (num 5))
(define my@variable (num 5))
state

================================================================================
EXAMPLE SESSION 8: Nested Expressions with Variables
================================================================================

(define a (num 2))
(define b (num 3))
(define c (num 4))
(define result (add (mult (id a) (id b)) (mult (id c) (num 5))))
state
(id result)

================================================================================
EXAMPLE SESSION 9: Functional Immutability Demo
================================================================================

(define pi (num 3.14159))
(define radius (num 10))
(define circumference (mult (num 2) (mult (id pi) (id radius))))
(id circumference)
(assign pi (num 3.14))
(remove pi)
(define pi (num 3.14))
(id pi)
state

================================================================================
REPL COMMANDS
================================================================================

state    - View all current variables
help     - Show available commands
quit     - Exit the REPL (or use: exit, q, Ctrl+D)

================================================================================
")
