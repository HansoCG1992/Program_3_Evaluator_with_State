#lang racket

;; ============================================================================
;; CS 441 - Program 3: Expression Evaluator with State
;; ============================================================================
;; This program implements an expression evaluator that maintains state
;; (variables and their values) and uses an Either/Result type system
;; for error handling.
;; ============================================================================

;; ============================================================================
;; EITHER/RESULT TYPE SYSTEM
;; ============================================================================

;; Define result constructors
(define (success value)
  (list 'success value))

(define (failure message)
  (list 'failure message))

;; Type predicates
(define (success? result)
  (and (list? result)
       (not (null? result))
       (equal? (first result) 'success)))

(define (failure? result)
  (and (list? result)
       (not (null? result))
       (equal? (first result) 'failure)))

;; Extract value from result, with default
(define (from-success default result)
  (if (success? result)
      (second result)
      default))

(define (from-failure default result)
  (if (failure? result)
      (second result)
      default))

;; ============================================================================
;; STATE MANAGEMENT
;; ============================================================================

;; State is an immutable association list of (id . value) pairs
;; value can be 'undefined or an actual number

(define empty-state '())

;; Special undefined marker
(define UNDEFINED 'undefined)

;; Check if identifier exists in state
(define (id-exists? id state)
  (assoc id state))

;; Get value of identifier from state
(define (get-id-value id state)
  (let ([binding (assoc id state)])
    (if binding
        (cdr binding)
        #f)))

;; Add new identifier to state (must not exist)
(define (add-id id value state)
  (if (id-exists? id state)
      #f  ; ID already exists
      (cons (cons id value) state)))

;; Update existing identifier in state
(define (update-id id value state)
  (cond
    [(null? state) #f]  ; ID not found
    [(equal? (caar state) id)
     (cons (cons id value) (cdr state))]
    [else
     (let ([rest (update-id id value (cdr state))])
       (if rest
           (cons (car state) rest)
           #f))]))

;; Remove identifier from state
(define (remove-id id state)
  (cond
    [(null? state) #f]  ; ID not found
    [(equal? (caar state) id) (cdr state)]
    [else
     (let ([rest (remove-id id (cdr state))])
       (if rest
           (cons (car state) rest)
           #f))]))

;; ============================================================================
;; IDENTIFIER VALIDATION
;; ============================================================================

;; Check if a symbol is a valid identifier
;; Must start with letter, followed by letters, digits, hyphens, underscores
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

;; ============================================================================
;; SAFE DIVISION
;; ============================================================================

(define (safe-div x y)
  (if (= y 0)
      (failure "division by zero")
      (success (/ x y))))

;; ============================================================================
;; EXPRESSION EVALUATOR WITH STATE
;; ============================================================================

;; eval-expr: expression state -> (result . state)
;; Returns a pair: (result . new-state)
;; where result is either (success value) or (failure message)

(define (eval-expr expr state)
  (cond
    ;; ---- NUM: numeric literal ----
    [(and (list? expr)
          (not (null? expr))
          (equal? (first expr) 'num))
     (if (and (= (length expr) 2) (number? (second expr)))
         (cons (success (second expr)) state)
         (cons (failure "num: invalid syntax") state))]

    ;; ---- ID: variable reference ----
    [(and (list? expr)
          (not (null? expr))
          (equal? (first expr) 'id))
     (if (not (= (length expr) 2))
         (cons (failure "id: invalid syntax") state)
         (let ([id-name (second expr)])
           (if (not (valid-id? id-name))
               (cons (failure (format "id: '~a' is not a valid identifier" id-name)) state)
               (let ([value (get-id-value id-name state)])
                 (cond
                   [(not value)
                    (cons (failure (format "id ~a: identifier not defined" id-name)) state)]
                   [(equal? value UNDEFINED)
                    (cons (failure (format "id ~a: identifier is undefined" id-name)) state)]
                   [else
                    (cons (success value) state)])))))]

    ;; ---- DEFINE: create new variable ----
    [(and (list? expr)
          (not (null? expr))
          (equal? (first expr) 'define))
     (cond
       [(< (length expr) 2)
        (cons (failure "define: missing identifier") state)]
       [(> (length expr) 3)
        (cons (failure "define: too many arguments") state)]
       [else
        (let ([id-name (second expr)])
          (if (not (valid-id? id-name))
              (cons (failure (format "define: '~a' is not a valid identifier" id-name)) state)
              (if (id-exists? id-name state)
                  (cons (failure (format "define ~a: identifier already defined" id-name)) state)
                  (if (= (length expr) 2)
                      ;; define without value -> undefined
                      (let ([new-state (add-id id-name UNDEFINED state)])
                        (cons (success id-name) new-state))
                      ;; define with value expression
                      (let* ([value-result (eval-expr (third expr) state)]
                             [result (car value-result)]
                             [result-state (cdr value-result)])
                        (if (failure? result)
                            (cons result state)  ; propagate failure, don't modify state
                            (let ([new-state (add-id id-name (from-success 0 result) state)])
                              (cons (success id-name) new-state))))))))])]

    ;; ---- ASSIGN: assign value to existing undefined variable ----
    [(and (list? expr)
          (not (null? expr))
          (equal? (first expr) 'assign))
     (if (not (= (length expr) 3))
         (cons (failure "assign: invalid syntax (expected: assign id expr)") state)
         (let ([id-name (second expr)])
           (if (not (valid-id? id-name))
               (cons (failure (format "assign: '~a' is not a valid identifier" id-name)) state)
               (let ([current-value (get-id-value id-name state)])
                 (cond
                   [(not current-value)
                    (cons (failure (format "assign ~a: identifier not defined" id-name)) state)]
                   [(not (equal? current-value UNDEFINED))
                    (cons (failure (format "assign ~a: identifier already has a value (data is immutable)" id-name)) state)]
                   [else
                    ;; evaluate the expression
                    (let* ([value-result (eval-expr (third expr) state)]
                           [result (car value-result)]
                           [result-state (cdr value-result)])
                      (if (failure? result)
                          (cons result state)  ; propagate failure
                          (let ([new-state (update-id id-name (from-success 0 result) state)])
                            (if new-state
                                (cons (success id-name) new-state)
                                (cons (failure (format "assign ~a: update failed" id-name)) state)))))])))))]

    ;; ---- REMOVE: remove variable from state ----
    [(and (list? expr)
          (not (null? expr))
          (equal? (first expr) 'remove))
     (if (not (= (length expr) 2))
         (cons (failure "remove: invalid syntax") state)
         (let ([id-name (second expr)])
           (if (not (valid-id? id-name))
               (cons (failure (format "remove: '~a' is not a valid identifier" id-name)) state)
               (if (not (id-exists? id-name state))
                   (cons (failure (format "remove ~a: identifier not defined" id-name)) state)
                   (let ([new-state (remove-id id-name state)])
                     (cons (success id-name) new-state))))))]

    ;; ---- ARITHMETIC OPERATIONS ----
    [(and (list? expr)
          (not (null? expr))
          (member (first expr) '(add sub mult div)))
     (if (not (= (length expr) 3))
         (cons (failure (format "~a: invalid syntax (expected 2 operands)" (first expr))) state)
         (let* ([op (first expr)]
                [left-result (eval-expr (second expr) state)]
                [left-val (car left-result)]
                [left-state (cdr left-result)])
           (if (failure? left-val)
               left-result  ; propagate failure
               (let* ([right-result (eval-expr (third expr) state)]
                      [right-val (car right-result)]
                      [right-state (cdr right-result)])
                 (if (failure? right-val)
                     right-result  ; propagate failure
                     (let ([x (from-success 0 left-val)]
                           [y (from-success 0 right-val)])
                       (cons
                        (cond
                          [(equal? op 'add) (success (+ x y))]
                          [(equal? op 'sub) (success (- x y))]
                          [(equal? op 'mult) (success (* x y))]
                          [(equal? op 'div) (safe-div x y)])
                        state)))))))]

    ;; ---- UNKNOWN OPERATION ----
    [else
     (cons (failure (format "unknown operation: ~a" (if (and (list? expr) (not (null? expr)))
                                                         (first expr)
                                                         expr)))
           state)]))

;; ============================================================================
;; REPL - READ-EVAL-PRINT LOOP
;; ============================================================================

;; Print the current state in a readable format
(define (print-state state)
  (if (null? state)
      (displayln "  State: (empty)")
      (begin
        (displayln "  State:")
        (for-each (λ (binding)
                    (let ([id (car binding)]
                          [val (cdr binding)])
                      (if (equal? val UNDEFINED)
                          (displayln (format "    ~a = <undefined>" id))
                          (displayln (format "    ~a = ~a" id val)))))
                  state))))

;; Print a result
(define (print-result result)
  (if (success? result)
      (displayln (format "  Success: ~a" (from-success 0 result)))
      (displayln (format "  Error: ~a" (from-failure "" result)))))

;; Main REPL loop
(define (repl [state empty-state])
  (display "\n> ")
  (flush-output)
  (let ([input (read)])
    (cond
      [(eof-object? input)
       (displayln "\nGoodbye!")
       (void)]
      [(or (equal? input 'quit) (equal? input 'exit) (equal? input 'q))
       (displayln "Goodbye!")
       (void)]
      [(equal? input 'state)
       (print-state state)
       (repl state)]
      [(equal? input 'help)
       (displayln "Commands:")
       (displayln "  (num N)              - numeric literal")
       (displayln "  (add E1 E2)          - addition")
       (displayln "  (sub E1 E2)          - subtraction")
       (displayln "  (mult E1 E2)         - multiplication")
       (displayln "  (div E1 E2)          - division")
       (displayln "  (id NAME)            - variable reference")
       (displayln "  (define NAME)        - define undefined variable")
       (displayln "  (define NAME EXPR)   - define and initialize variable")
       (displayln "  (assign NAME EXPR)   - assign to undefined variable")
       (displayln "  (remove NAME)        - remove variable from state")
       (displayln "  state                - show current state")
       (displayln "  help                 - show this help")
       (displayln "  quit/exit/q          - exit REPL")
       (repl state)]
      [else
       (let* ([result-pair (eval-expr input state)]
              [result (car result-pair)]
              [new-state (cdr result-pair)])
         (print-result result)
         (when (failure? result)
           (displayln "  State unchanged"))
         (repl new-state))])))

;; ============================================================================
;; TESTING (from original code, converted to Either)
;; ============================================================================

(displayln "=== Running Initial Tests ===\n")

(displayln "Test 1: (num 5)")
(let ([result (eval-expr '(num 5) empty-state)])
  (print-result (car result))
  (print-state (cdr result)))

(displayln "\nTest 2: (add (num 5) (mult (num 2) (num 3)))  ; 5 + (2*3) = 11")
(let ([result (eval-expr '(add (num 5) (mult (num 2) (num 3))) empty-state)])
  (print-result (car result))
  (print-state (cdr result)))

(displayln "\nTest 3: (sub (num 20) (div (add (mult (num 4) (num 5)) (num 10)) (num 6)))")
(displayln "        ; 20 - (((4*5)+10)/6) = 20 - (30/6) = 15")
(let ([result (eval-expr '(sub (num 20) (div (add (mult (num 4) (num 5)) (num 10)) (num 6))) empty-state)])
  (print-result (car result))
  (print-state (cdr result)))

(displayln "\nTest 4: (div (num 5) (sub (num 5) (num 5)))  ; 5 / (5-5) = division by zero")
(let ([result (eval-expr '(div (num 5) (sub (num 5) (num 5))) empty-state)])
  (print-result (car result))
  (print-state (cdr result)))

(displayln "\n=== Testing State Management ===\n")

(displayln "Test 5: Define variable 'a'")
(let* ([result1 (eval-expr '(define a) empty-state)]
       [state1 (cdr result1)])
  (print-result (car result1))
  (print-state state1)

  (displayln "\nTest 6: Try to use undefined 'a'")
  (let ([result2 (eval-expr '(id a) state1)])
    (print-result (car result2)))

  (displayln "\nTest 7: Assign value to 'a'")
  (let* ([result3 (eval-expr '(assign a (num 10)) state1)]
         [state2 (cdr result3)])
    (print-result (car result3))
    (print-state state2)

    (displayln "\nTest 8: Use 'a' in expression")
    (let ([result4 (eval-expr '(add (id a) (num 5)) state2)])
      (print-result (car result4)))

    (displayln "\nTest 9: Define 'b' with initial value")
    (let* ([result5 (eval-expr '(define b (add (id a) (num 1))) state2)]
           [state3 (cdr result5)])
      (print-result (car result5))
      (print-state state3)

      (displayln "\nTest 10: Remove 'a'")
      (let* ([result6 (eval-expr '(remove a) state3)]
             [state4 (cdr result6)])
        (print-result (car result6))
        (print-state state4)

        (displayln "\nTest 11: Try to use removed 'a'")
        (let ([result7 (eval-expr '(id a) state4)])
          (print-result (car result7)))))))

(displayln "\n=== Additional Edge Case Tests ===\n")

(displayln "Test 12: Try to define same variable twice")
(let* ([result1 (eval-expr '(define x (num 5)) empty-state)]
       [state1 (cdr result1)])
  (print-result (car result1))
  (let ([result2 (eval-expr '(define x (num 10)) state1)])
    (print-result (car result2))))

(displayln "\nTest 13: Try to assign to non-existent variable")
(let ([result (eval-expr '(assign z (num 42)) empty-state)])
  (print-result (car result)))

(displayln "\nTest 14: Try to assign to already-assigned variable")
(let* ([result1 (eval-expr '(define y (num 7)) empty-state)]
       [state1 (cdr result1)])
  (let ([result2 (eval-expr '(assign y (num 14)) state1)])
    (print-result (car result2))))

(displayln "\nTest 15: Valid identifier with underscores and hyphens")
(let* ([result1 (eval-expr '(define my_var-1 (num 100)) empty-state)]
       [state1 (cdr result1)])
  (print-result (car result1))
  (print-state state1))

(displayln "\nTest 16: Invalid identifier starting with number")
(let ([result (eval-expr '(define 1invalid (num 50)) empty-state)])
  (print-result (car result)))

(displayln "\n\n=== Starting REPL ===")
(displayln "Type 'help' for commands, 'quit' to exit\n")
(repl)
