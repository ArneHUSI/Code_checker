; This file contains various errors that are to be detected by the code checker

(define var 4)

(define VAR 5)

(define-struct bla [x y z])

(define Bla (make-bla 1 2 3))

(define BLA (make-bla 1 2 3))

(define B_L_A (make-bla 1 2 3))

(define bla (make-bla 1 2 3))

; Interpretation: Some other struct Blubb

(define-struct blubb [r s])

(define (func_without_sign r) (* 4 5 ))

; number -> number
(define (func_with_sign r) (* 4 5 ))

; func_withWrong_sign: number -> number
(define (func_withWrong_sign r s) (* 4 5 ))

; func_withWrong_sign: number number -> number
(define (func_withWrong_sign r) (* 4 5 ))

; func_withWrong_sign: number number --> number
(define (func_withWrong_sign r s) (* 4 5 ))

; func: [T1 -> T2] T1 -> T2
(define (f g h) (g h))
